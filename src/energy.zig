const std = @import("std");
const sti = @import("sti");

const card = @import("card.zig");
const map = @import("map.zig");

const Allocator = sti.Memory.Allocator;

pub const max_link_span = 3;
pub const allowed_tiles = sti.EnumBitVector(map.TileTypes).create(.{ .stone, .metal });

pub const Mode = enum {
    place,
    remove,
};

pub const ToolState = struct {
    mode: ?Mode,
    hovered_tile: ?map.TilePosition,

    pub const default: ToolState = .{
        .mode = null,
        .hovered_tile = null,
    };
};

pub const Endpoint = union(enum) {
    pole: map.TilePosition,
    structure: map.BuildingId,

    pub fn eql(self: Endpoint, other: Endpoint) bool {
        return switch (self) {
            .pole => |pos| switch (other) {
                .pole => |other_pos| sti.meta.eql(pos, other_pos),
                else => false,
            },
            .structure => |building_id| switch (other) {
                .structure => |other_building_id| sti.meta.eql(building_id, other_building_id),
                else => false,
            },
        };
    }

    pub fn tile(self: Endpoint, tilemap: *const map.Map) map.TilePosition {
        return switch (self) {
            .pole => |pos| pos,
            .structure => |building_id| tilemap.get_building_representative_tile(building_id) orelse unreachable,
        };
    }

    pub fn limit(self: Endpoint) usize {
        return switch (self) {
            .pole => 2,
            .structure => 1,
        };
    }

    pub fn degree(self: Endpoint, tilemap: *const map.Map) usize {
        var total: usize = 0;
        for (tilemap.energy_links.as_slice()) |link| {
            if (link.a.eql(self) or link.b.eql(self)) {
                total += 1;
            }
        }
        return total;
    }
};

pub const Link = struct {
    a: Endpoint,
    b: Endpoint,
};

pub const EndpointList = struct {
    items: [4]Endpoint,
    len: usize,

    pub fn init() EndpointList {
        return .{
            .items = undefined,
            .len = 0,
        };
    }

    pub fn push(self: *EndpointList, endpoint: Endpoint) void {
        self.items[self.len] = endpoint;
        self.len += 1;
    }

    pub fn as_slice(self: *const EndpointList) []const Endpoint {
        return self.items[0..self.len];
    }

    pub fn contains(self: *const EndpointList, endpoint: Endpoint) bool {
        for (self.as_slice()) |existing| {
            if (existing.eql(endpoint)) return true;
        }
        return false;
    }

    pub fn append_unique(self: *EndpointList, endpoint: Endpoint) void {
        if (self.contains(endpoint)) return;
        self.push(endpoint);
    }
};

pub const PlacementPreview = struct {
    can_place: bool,
    links: EndpointList,
};

const ScannedEndpoint = struct {
    endpoint: Endpoint,
    tile: map.TilePosition,
};

pub fn structure_role(structure: map.Structure) card.PowerRole {
    return switch (structure.structure_type) {
        .card => |c| card.get_power_role(c),
        else => .none,
    };
}

fn compare_tile_order(a: map.TilePosition, b: map.TilePosition) bool {
    if (a.data[1] != b.data[1]) return a.data[1] < b.data[1];
    return a.data[0] < b.data[0];
}

fn get_closest_building_tile(tilemap: *const map.Map, building_id: map.BuildingId, other_tile: map.TilePosition) map.TilePosition {
    var best: ?map.TilePosition = null;
    var best_same_axis = false;
    var best_distance: usize = 0;
    var best_axis_progress: usize = 0;

    for (tilemap.structures.iter()) |structure| {
        if (structure.building_id == null or !sti.meta.eql(structure.building_id.?, building_id)) continue;

        const tile = structure.position;
        const same_axis = tile.data[0] == other_tile.data[0] or tile.data[1] == other_tile.data[1];
        const distance_x: usize = @intCast(@abs(tile.data[0] - other_tile.data[0]));
        const distance_y: usize = @intCast(@abs(tile.data[1] - other_tile.data[1]));
        const distance = distance_x + distance_y;
        const axis_progress = if (tile.data[0] == other_tile.data[0]) distance_y else if (tile.data[1] == other_tile.data[1]) distance_x else 0;

        if (best == null) {
            best = tile;
            best_same_axis = same_axis;
            best_distance = distance;
            best_axis_progress = axis_progress;
            continue;
        }

        if (same_axis and !best_same_axis) {
            best = tile;
            best_same_axis = true;
            best_distance = distance;
            best_axis_progress = axis_progress;
            continue;
        }

        if (same_axis == best_same_axis and distance < best_distance) {
            best = tile;
            best_distance = distance;
            best_axis_progress = axis_progress;
            continue;
        }

        if (same_axis == best_same_axis and distance == best_distance and axis_progress > best_axis_progress) {
            best = tile;
            best_axis_progress = axis_progress;
            continue;
        }

        if (same_axis == best_same_axis and distance == best_distance and axis_progress == best_axis_progress and compare_tile_order(tile, best.?)) {
            best = tile;
        }
    }

    return best orelse unreachable;
}

fn get_render_endpoint_tile(tilemap: *const map.Map, endpoint: Endpoint, other_endpoint: Endpoint) map.TilePosition {
    return switch (endpoint) {
        .pole => |pos| pos,
        .structure => |building_id| get_closest_building_tile(tilemap, building_id, other_endpoint.tile(tilemap)),
    };
}

fn get_endpoint_at(tilemap: *const map.Map, pos: map.TilePosition) ?Endpoint {
    const structure = tilemap.structures.get_const(pos) orelse return null;
    return switch (structure.structure_type) {
        .power_pole => .{ .pole = pos },
        .card => if (structure_role(structure) != .none and structure.building_id != null) .{ .structure = structure.building_id.? } else null,
        else => null,
    };
}

pub fn has_link(tilemap: *const map.Map, a: Endpoint, b: Endpoint) bool {
    for (tilemap.energy_links.as_slice()) |link| {
        if ((link.a.eql(a) and link.b.eql(b)) or
            (link.a.eql(b) and link.b.eql(a)))
        {
            return true;
        }
    }
    return false;
}

fn neighbors(tilemap: *const map.Map, endpoint: Endpoint) EndpointList {
    var list = EndpointList.init();
    for (tilemap.energy_links.as_slice()) |link| {
        if (link.a.eql(endpoint)) {
            list.push(link.b);
        } else if (link.b.eql(endpoint)) {
            list.push(link.a);
        }
    }
    return list;
}

fn reaches_target(tilemap: *const map.Map, current: Endpoint, target: Endpoint, previous: ?Endpoint) bool {
    const current_neighbors = neighbors(tilemap, current);
    for (current_neighbors.as_slice()) |neighbor| {
        if (previous) |prev| {
            if (prev.eql(neighbor)) continue;
        }
        if (neighbor.eql(target)) return true;
        if (reaches_target(tilemap, neighbor, target, current)) return true;
    }
    return false;
}

pub fn are_connected(tilemap: *const map.Map, a: Endpoint, b: Endpoint) bool {
    if (a.eql(b)) return true;
    return reaches_target(tilemap, a, b, null);
}

fn same_axis_and_in_range(a: map.TilePosition, b: map.TilePosition) bool {
    if (a.data[0] == b.data[0]) {
        const dist = @abs(a.data[1] - b.data[1]);
        return dist > 0 and dist <= max_link_span;
    }
    if (a.data[1] == b.data[1]) {
        const dist = @abs(a.data[0] - b.data[0]);
        return dist > 0 and dist <= max_link_span;
    }
    return false;
}

fn scan_direction(tilemap: *const map.Map, start: map.TilePosition, dir: map.Direction) ?ScannedEndpoint {
    var pos = start;
    var step: usize = 0;
    while (step < max_link_span) : (step += 1) {
        pos = dir.pos_in_dir(pos);
        if (tilemap.get_endpoint_at(pos)) |endpoint| {
            return .{
                .endpoint = endpoint,
                .tile = pos,
            };
        }
    }
    return null;
}

fn can_attach_to_candidate(tilemap: *const map.Map, endpoint: Endpoint, endpoint_tile_pos: map.TilePosition, candidate: ScannedEndpoint) bool {
    if (!same_axis_and_in_range(endpoint_tile_pos, candidate.tile)) return false;
    if (has_link(tilemap, endpoint, candidate.endpoint)) return false;
    return candidate.endpoint.degree(tilemap) < candidate.endpoint.limit();
}

fn can_select_candidate(tilemap: *const map.Map, selected: *const EndpointList, candidate: Endpoint) bool {
    for (selected.as_slice()) |existing| {
        if (are_connected(tilemap, existing, candidate)) return false;
    }
    return true;
}

fn select_attachment_candidates(tilemap: *const map.Map, endpoint: Endpoint, candidates: EndpointList, max_links: usize) EndpointList {
    var selected = EndpointList.init();
    const remaining_capacity = endpoint.limit() -| endpoint.degree(tilemap);
    const selection_limit = @min(max_links, remaining_capacity);

    for (candidates.as_slice()) |candidate| {
        if (selected.len >= selection_limit) break;
        if (!can_select_candidate(tilemap, &selected, candidate)) continue;
        selected.append_unique(candidate);
    }

    return selected;
}

const testing = sti.testing;
const test_allocator = sti.Memory.page_allocator;

fn make_test_map() !map.Map {
    var tilemap = map.Map.init();
    var chunk = map.TileChunk.init(.{ .tile_type = .stone });
    chunk.position = .{ .data = .{ 0, 0 } };
    try tilemap.chunks.data.put(test_allocator, .{ .data = .{ 0, 0 } }, chunk);
    return tilemap;
}

fn add_test_building(tilemap: *map.Map, allocator: Allocator, c: card.CardEnum, positions: []const map.TilePosition) !map.BuildingId {
    const building_id = tilemap.allocate_building_id();
    for (positions) |pos| {
        try tilemap.structures.add(allocator, .{
            .position = pos,
            .structure_type = .{ .card = c },
            .direction = null,
            .building_id = building_id,
        });
    }
    return building_id;
}

test "power pole links to nearby pole" {
    var tilemap = try make_test_map();

    // y
    // 2  p
    // 1
    // 0  p
    //    0

    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 0 } }));
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 2 } }));
    try testing.expect_equal(@as(usize, 1), tilemap.energy_links.len());
}

test "power pole does not link beyond span" {
    var tilemap = try make_test_map();

    // y
    // 4  p
    // 3
    // 2
    // 1
    // 0  p
    //    0

    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 0 } }));
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 4 } }));
    try testing.expect_equal(@as(usize, 0), tilemap.energy_links.len());
}

test "power pole placement selects a valid subset of nearby links" {
    var tilemap = try make_test_map();

    // y
    // 6    p
    // 5
    // 4  p ? p
    // 3
    // 2    p
    //    2 3 4 5 6
    //
    // the center pole can see four candidates
    // but it should only pick two of them

    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 4, 2 } }));
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 4, 6 } }));
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 2, 4 } }));
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 6, 4 } }));

    const preview = tilemap.get_placement_preview(.{ .data = .{ 4, 4 } });
    try testing.expect(preview.can_place);
    try testing.expect_equal(@as(usize, 2), preview.links.len);
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 4, 4 } }));
    try testing.expect_equal(@as(usize, 2), tilemap.energy_links.len());
}

test "producer building acts as a virtual endpoint" {
    var tilemap = try make_test_map();

    // y
    // 2  p
    // 1
    // 0  s
    //    0
    //
    // s is a powered structure tile acting as a building endpoint

    try tilemap.structures.add(test_allocator, .{
        .position = .{ .data = .{ 0, 0 } },
        .structure_type = .{ .card = .solar_panel },
        .direction = null,
        .building_id = tilemap.allocate_building_id(),
    });

    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 2 } }));
    try testing.expect_equal(@as(usize, 1), tilemap.energy_links.len());
    try testing.expect_equal(@as(usize, 1), (Endpoint{ .structure = tilemap.get_building_id_at(.{ .data = .{ 0, 0 } }).? }).degree(&tilemap));
}

test "removing a power pole clears attached links" {
    var tilemap = try make_test_map();

    // before remove
    //
    // y
    // 2  p
    // 1
    // 0  p
    //    0

    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 0 } }));
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 2 } }));
    try testing.expect(tilemap.remove_power_pole(test_allocator, .{ .data = .{ 0, 0 } }));
    try testing.expect_equal(@as(usize, 0), tilemap.energy_links.len());
}

test "powered building links when placed next to existing pole" {
    var tilemap = try make_test_map();

    // y
    // 2  p .
    // 1  s s
    // 0  s s
    //    0 1

    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 2 } }));
    const building_id = try add_test_building(&tilemap, test_allocator, .solar_panel, &.{
        .{ .data = .{ 0, 0 } },
        .{ .data = .{ 1, 0 } },
        .{ .data = .{ 0, 1 } },
        .{ .data = .{ 1, 1 } },
    });

    try testing.expect(try tilemap.attach_building_endpoint(test_allocator, building_id));
    try testing.expect_equal(@as(usize, 1), tilemap.energy_links.len());
    try testing.expect_equal(@as(usize, 1), (Endpoint{ .structure = building_id }).degree(&tilemap));
}

test "powered building selects one nearby pole when several are valid" {
    var tilemap = try make_test_map();

    // y
    // 2  p .
    // 1  s s
    // 0  s s p
    //    0 1 2
    //
    // the building can see one pole above and one to the right
    // it should choose one valid attachment instead of failing

    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 2 } }));
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 2, 0 } }));
    const building_id = try add_test_building(&tilemap, test_allocator, .solar_panel, &.{
        .{ .data = .{ 0, 0 } },
        .{ .data = .{ 1, 0 } },
        .{ .data = .{ 0, 1 } },
        .{ .data = .{ 1, 1 } },
    });

    try testing.expect(try tilemap.attach_building_endpoint(test_allocator, building_id));
    try testing.expect_equal(@as(usize, 1), (Endpoint{ .structure = building_id }).degree(&tilemap));
    try testing.expect_equal(@as(usize, 1), tilemap.energy_links.len());
}

test "power pole can place when two visible candidates are already connected" {
    var tilemap = try make_test_map();

    // y
    // 2  p ? 
    // 1
    // 0  p . p
    //    0 1 2
    //
    // the new pole at 2,2 can see the pole below and the pole to the left
    // those two existing poles are already connected through 0,0
    // so the new pole should still place and keep only one safe link

    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 0 } }));
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 0, 2 } }));
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 2, 0 } }));

    const preview = tilemap.get_placement_preview(.{ .data = .{ 2, 2 } });
    try testing.expect(preview.can_place);
    try testing.expect_equal(@as(usize, 1), preview.links.len);
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 2, 2 } }));
    try testing.expect_equal(@as(usize, 3), tilemap.energy_links.len());
}

test "multi tile powered building is one endpoint" {
    var tilemap = try make_test_map();

    // y
    // 5  s s
    // 4  s s
    //    4 5
    //
    // all four tiles belong to one building id

    const building_id = try add_test_building(&tilemap, test_allocator, .solar_panel, &.{
        .{ .data = .{ 4, 4 } },
        .{ .data = .{ 5, 4 } },
        .{ .data = .{ 4, 5 } },
        .{ .data = .{ 5, 5 } },
    });

    const a = tilemap.get_endpoint_at(.{ .data = .{ 4, 4 } }).?;
    const b = tilemap.get_endpoint_at(.{ .data = .{ 5, 5 } }).?;
    try testing.expect(a.eql(b));
    try testing.expect_equal(@as(map.BuildingId, building_id), a.structure);
}

test "multi tile powered building rejects second pole connection" {
    var tilemap = try make_test_map();

    // step 1
    //
    // y
    // 5  s s
    // 4  s s
    // 3
    // 2  . . p
    //    4 5 6
    //
    // step 2
    //
    // y
    // 5  s s . p
    // 4  s s
    // 3
    // 2  . . p
    //    4 5 6 7
    //
    // the building already has one link
    // adding another nearby pole should not give it a second one

    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 4, 2 } }));
    const building_id = try add_test_building(&tilemap, test_allocator, .solar_panel, &.{
        .{ .data = .{ 4, 4 } },
        .{ .data = .{ 5, 4 } },
        .{ .data = .{ 4, 5 } },
        .{ .data = .{ 5, 5 } },
    });

    try testing.expect(try tilemap.attach_building_endpoint(test_allocator, building_id));
    try testing.expect(try tilemap.place_power_pole(test_allocator, .{ .data = .{ 7, 5 } }));
    try testing.expect(try tilemap.attach_building_endpoint(test_allocator, building_id));
    try testing.expect_equal(@as(usize, 1), (Endpoint{ .structure = building_id }).degree(&tilemap));
}

test "render anchor picks top tile when pole is above building" {
    var tilemap = try make_test_map();

    // y
    // 5  s s
    // 4  s s
    // 3
    // 2  p
    //    4 5
    //
    // the wire should anchor to 4,4

    const building_id = try add_test_building(&tilemap, test_allocator, .solar_panel, &.{
        .{ .data = .{ 4, 4 } },
        .{ .data = .{ 5, 4 } },
        .{ .data = .{ 4, 5 } },
        .{ .data = .{ 5, 5 } },
    });

    const tile = tilemap.get_render_endpoint_tile(.{ .structure = building_id }, .{ .pole = .{ .data = .{ 4, 2 } } });
    try testing.expect_equal(@as(isize, 4), tile.data[0]);
    try testing.expect_equal(@as(isize, 4), tile.data[1]);
}

test "render anchor picks left tile when pole is left of building" {
    var tilemap = try make_test_map();

    // y
    // 5  s s
    // 4  p s s
    //    2 3 4 5
    //
    // the wire should anchor to 4,4

    const building_id = try add_test_building(&tilemap, test_allocator, .solar_panel, &.{
        .{ .data = .{ 4, 4 } },
        .{ .data = .{ 5, 4 } },
        .{ .data = .{ 4, 5 } },
        .{ .data = .{ 5, 5 } },
    });

    const tile = tilemap.get_render_endpoint_tile(.{ .structure = building_id }, .{ .pole = .{ .data = .{ 2, 4 } } });
    try testing.expect_equal(@as(isize, 4), tile.data[0]);
    try testing.expect_equal(@as(isize, 4), tile.data[1]);
}

test "render anchor can differ from representative tile" {
    var tilemap = try make_test_map();

    // insertion order makes 5,5 the representative tile
    //
    // y
    // 5  s r
    // 4  a s
    // 3
    // 2  p
    //    4 5
    //
    // r is the representative tile
    // a is the tile we actually want to anchor to

    const building_id = try add_test_building(&tilemap, test_allocator, .solar_panel, &.{
        .{ .data = .{ 5, 5 } },
        .{ .data = .{ 4, 4 } },
        .{ .data = .{ 5, 4 } },
        .{ .data = .{ 4, 5 } },
    });

    const representative = tilemap.get_building_representative_tile(building_id).?;
    const tile = tilemap.get_render_endpoint_tile(.{ .structure = building_id }, .{ .pole = .{ .data = .{ 4, 2 } } });
    try testing.expect(!sti.meta.eql(representative, tile));
    try testing.expect_equal(@as(isize, 4), tile.data[0]);
    try testing.expect_equal(@as(isize, 4), tile.data[1]);
}
