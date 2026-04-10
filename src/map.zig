const sti = @import("sti");

const rl = @import("raylib");

const render = @import("render.zig");
const noise = @import("noise.zig");
const card = @import("card.zig");
const energy = @import("energy.zig");

const Allocator = sti.Memory.Allocator;

pub const BuildingId = struct {
    value: u64,

    pub fn init(value: u64) BuildingId {
        return .{ .value = value };
    }

    pub fn next(self: BuildingId) BuildingId {
        return .init(self.value + 1);
    }
};

pub const StructureType = union(enum) {
    card: card.CardEnum,
    belt,
    power_pole,
};

pub const Structure = struct {
    position: TilePosition,
    structure_type: StructureType,
    direction: ?Direction,
    building_id: ?BuildingId,
};

pub const Structures = struct {
    const Self = @This();

    tiles: sti.ArrayList(Structure),
    position_map: sti.HashMap(TilePosition, usize),

    pub fn init() Self {
        return .{ .tiles = .init(), .position_map = .init() };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.tiles.deinit(allocator);
        self.position_map.deinit(allocator.to_std());
    }

    pub fn add(self: *Self, allocator: Allocator, structure: Structure) !void {
        const index = self.tiles.len();
        try self.tiles.push(allocator, structure);
        _ = try self.position_map.insert(allocator.to_std(), structure.position, index);
    }

    pub fn get(self: *Self, position: TilePosition) ?*Structure {
        if (self.position_map.get(position)) |index| {
            return &self.tiles.as_slice()[index];
        }
        return null;
    }

    pub fn get_const(self: *const Self, position: TilePosition) ?Structure {
        if (self.position_map.get(position)) |index| {
            return self.tiles.as_slice()[index];
        }
        return null;
    }

    pub fn remove(self: *Self, allocator: Allocator, position: TilePosition) ?Structure {
        if (self.position_map.remove(position)) |index| {
            const removed = self.tiles.swap_remove(index);
            // Update position_map for swapped element
            if (index < self.tiles.len()) {
                const swapped = self.tiles.as_slice()[index];
                _ = self.position_map.insert(allocator.to_std(), swapped.position, index) catch return removed;
            }
            return removed;
        }
        return null;
    }

    pub fn has_structure(self: *const Self, position: TilePosition) bool {
        return self.position_map.contains_key(position);
    }

    pub fn iter(self: *const Self) []const Structure {
        return self.tiles.as_slice();
    }
};

pub fn Position(comptime T: type, comptime D: usize) type {
    return @Vector(D, T);
}

pub const ChunkPosition: type = struct {
    const Self = @This();
    data: Position(isize, 2),

    pub fn to_tile_position(self: Self, subchunk_position: TilePosition) TilePosition {
        return .{ .data = .{ (self.data[0] * ChunkSize) + subchunk_position.data[0], (self.data[1] * ChunkSize) + subchunk_position.data[1] } };
    }

    pub fn to_string(self: Self, allocator: Allocator) ![]u8 {
        return try sti.format.alloc_print(allocator, "x:{d} y:{d}", .{ self.data[0], self.data[1] });
    }
};
pub const TilePosition: type = struct {
    const Self = @This();
    data: Position(isize, 2),

    pub fn to_world_position(self: Self) render.WorldPosition {
        const size = render.TileRenderSettings.size;
        var x: f32 = @floatFromInt(self.data[0]);
        x *= (size);
        x += -ChunkSize / 2.0 + (size / 2.0);
        var z: f32 = @floatFromInt(self.data[1]);
        z *= (size);
        z += -ChunkSize / 2.0 + (size / 2.0);
        return .{ .data = .{ .x = x, .y = size / 2.0, .z = z } };
    }
    pub fn to_chunk_and_subchunk_position(self: Self) struct { chunk_position: ChunkPosition, subchunk_position: TilePosition } {
        const chunk_position: ChunkPosition = .{
            .data = .{ @divFloor(self.data[0], ChunkSize), @divFloor(self.data[1], ChunkSize) },
        };
        var tile_x = @rem(self.data[0], ChunkSize);
        tile_x = if (tile_x < 0) ChunkSize + tile_x else tile_x;
        var tile_y = @rem(self.data[1], ChunkSize);
        tile_y = if (tile_y < 0) ChunkSize + tile_y else tile_y;
        const tile_position: TilePosition = .{ .data = .{ tile_x, tile_y } };
        return .{ .chunk_position = chunk_position, .subchunk_position = tile_position };
    }
    pub fn to_string(self: Self, allocator: Allocator) ![]u8 {
        return try sti.format.alloc_print(allocator, "x:{d} y:{d}", .{ self.data[0], self.data[1] });
    }
};

pub const Direction = enum(u2) {
    const Self = @This();

    up = 0,
    left = 1,
    down = 2,
    right = 3,

    pub fn move_from(self: Self, pos: *TilePosition) void {
        switch (self) {
            .up => pos.data[1] -|= 1,
            .left => pos.data[0] -|= 1,
            .down => pos.data[1] +|= 1,
            .right => pos.data[0] +|= 1,
        }
    }

    pub fn pos_in_dir(self: Self, pos: TilePosition) TilePosition {
        return .{ .data = switch (self) {
            .up => .{ pos.data[0], pos.data[1] -| 1 },
            .left => .{ pos.data[0] -| 1, pos.data[1] },
            .down => .{ pos.data[0], pos.data[1] +| 1 },
            .right => .{ pos.data[0] +| 1, pos.data[1] },
        } };
    }

    pub inline fn rotate(a: Self, b: Self) Self {
        return @enumFromInt(@intFromEnum(a) +% @intFromEnum(b));
    }

    pub inline fn mirror(a: Self) Self {
        return @enumFromInt(@intFromEnum(a) ^ 2);
    }

    pub inline fn is_vertical(a: Self) bool {
        return @intFromEnum(a) & 1 == 0;
    }
};

<<<<<<< HEAD
pub const TileTypes = enum { stone, lava };
=======
pub const TileTypes = enum { stone, lava, metal };
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
pub const Tile = struct {
    tile_type: TileTypes,
<<<<<<< HEAD

    pub fn get_color(self: Self) rl.Color {
        switch (self.tile_type) {
            .stone => {
                return .gray;
            },
            .lava => {
                return .orange;
            },
        }
    }
=======
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
};

pub const ChunkSize = 32;
pub const TileChunk = struct {
    const Perlin = noise.Perlin(f64, 0.1);
    const Self = @This();
    position: ChunkPosition,
    heightmap: sti.Array2D(f64, TilePosition{ .data = .{ ChunkSize, ChunkSize } }),
    tiles: sti.Array2D(Tile, TilePosition{ .data = .{ ChunkSize, ChunkSize } }),

    pub fn init(tile: Tile) Self {
        return .{
            .position = undefined,
            .heightmap = .init(0),
            .tiles = .init(tile),
        };
    }
    pub fn init_undefined() Self {
        return .{ .tiles = .init_undefined, .heightmap = .init_undefined, .position = undefined };
    }
    pub fn set(self: *Self, position: TilePosition, tile: Tile) *Tile {
        return self.tiles.set(position, tile);
    }

    pub fn generate_chunk(self: *Self, rng: *sti.Random) void {
        _ = rng;
        self.generate_heightmap();
        for (0..ChunkSize) |x| {
            for (0..ChunkSize) |y| {
                const subchunk_position: TilePosition = .{ .data = .{ @intCast(x), @intCast(y) } };
                const height = self.heightmap.read(subchunk_position);
                const tile_type: TileTypes = if (height > 0) .stone else .lava;
                const tile: Tile = .{ .tile_type = tile_type };
                _ = self.tiles.set(subchunk_position, tile);
            }
        }
    }
    pub fn generate_heightmap(self: *Self) void {
        for (0..ChunkSize) |x| {
            for (0..ChunkSize) |y| {
                const subchunk_position: TilePosition = .{ .data = .{ @intCast(x), @intCast(y) } };
                const global_position = self.position.to_tile_position(subchunk_position);
                _ = self.heightmap.set(subchunk_position, Perlin.generate(global_position));
            }
        }
    }
    pub fn generate_height(self: *const Self, subchunk_position: TilePosition) f64 {
        const global_position = self.position.to_tile_position(subchunk_position);
        return Perlin.generate(global_position);
    }
};

pub const TileChunks = struct {
    const Self = @This();
    data: sti.Chunks(ChunkPosition, TileChunk) = .{},

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.data.data.deinit(allocator.to_std());
    }

    pub fn get_tile(self: *Self, position: TilePosition) ?*Tile {
        const positions = position.to_chunk_and_subchunk_position();
        const chunk_position = positions.chunk_position;
        const subchunk_position = positions.subchunk_position;

        var chunk = self.data.data.get_ptr(chunk_position) orelse return null;
        const tile = chunk.tiles.get(subchunk_position);
        return tile;
    }

    pub fn get_tile_const(self: *const Self, position: TilePosition) ?*const Tile {
        const positions = position.to_chunk_and_subchunk_position();
        const chunk_position = positions.chunk_position;
        const subchunk_position = positions.subchunk_position;

        const chunk = self.data.data.get_ptr(chunk_position) orelse return null;
        return chunk.tiles.get(subchunk_position);
    }

    pub fn read_tile(self: *const Self, position: TilePosition) *const Tile {
        const positions = position.to_chunk_and_subchunk_position();
        const chunk_position = positions.chunk_position;
        const subchunk_position = positions.subchunk_position;
        var chunk = self.data.data.get_ptr(chunk_position) orelse {
            const msg = sti.GameErrors.chunk_not_found(sti.page_allocator, chunk_position) catch "cannot get chunk";
            sti.debug.panic("{s}", .{msg});
        };
        const tile = chunk.tiles.get(subchunk_position);
        return tile;
    }

    pub fn generate_chunk(self: *Self, allocator: Allocator, chunk_position: ChunkPosition, rng: *sti.Random) !void {
        var generated_chunk = TileChunk.init_undefined();
        generated_chunk.position = chunk_position;
        generated_chunk.generate_chunk(rng);
        try self.data.put(allocator, chunk_position, generated_chunk);
    }
};

pub const Map = struct {
    const Self = @This();

    chunks: TileChunks = .{},
    structures: Structures = .init(),
    energy_links: sti.ArrayList(energy.Link) = .init(),
    next_building_id: BuildingId,

    pub fn init() Self {
        return .{
            .chunks = .{ .data = .{} },
            .structures = .init(),
            .energy_links = .init(),
            .next_building_id = BuildingId.init(1),
        };
    }

<<<<<<< HEAD
=======
    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.chunks.deinit(allocator);
        self.structures.deinit(allocator);
        self.energy_links.deinit(allocator);
    }

    pub fn allocate_building_id(self: *Self) BuildingId {
        const id = self.next_building_id;
        self.next_building_id = self.next_building_id.next();
        return id;
    }

    pub fn get_building_id_at(self: *const Self, pos: TilePosition) ?BuildingId {
        const structure = self.structures.get_const(pos) orelse return null;
        return structure.building_id;
    }

    pub fn get_building_representative_tile(self: *const Self, building_id: BuildingId) ?TilePosition {
        for (self.structures.iter()) |structure| {
            if (structure.building_id) |current| {
                if (sti.meta.eql(current, building_id)) return structure.position;
            }
        }
        return null;
    }

    pub fn get_building_role(self: *const Self, building_id: BuildingId) card.PowerRole {
        const tile = self.get_building_representative_tile(building_id) orelse return .none;
        const structure = self.structures.get_const(tile) orelse return .none;
        return energy.structure_role(structure);
    }

    pub fn get_endpoint_at(self: *const Self, pos: TilePosition) ?energy.Endpoint {
        const structure = self.structures.get_const(pos) orelse return null;
        return switch (structure.structure_type) {
            .power_pole => .{ .pole = pos },
            .card => if (energy.structure_role(structure) != .none and structure.building_id != null) .{ .structure = structure.building_id.? } else null,
            else => null,
        };
    }

    pub fn get_render_endpoint_tile(self: *const Self, endpoint: energy.Endpoint, other_endpoint: energy.Endpoint) TilePosition {
        return switch (endpoint) {
            .pole => |pos| pos,
            .structure => |building_id| blk: {
                const other_tile = other_endpoint.tile(self);
                var best: ?TilePosition = null;
                var best_same_axis = false;
                var best_distance: usize = 0;
                var best_axis_progress: usize = 0;

                for (self.structures.iter()) |structure| {
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

                    if (same_axis == best_same_axis and distance == best_distance and axis_progress == best_axis_progress) {
                        if (tile.data[1] < best.?.data[1] or (tile.data[1] == best.?.data[1] and tile.data[0] < best.?.data[0])) {
                            best = tile;
                        }
                    }
                }

                break :blk best orelse unreachable;
            },
        };
    }

    pub fn attach_building_endpoint(self: *Self, allocator: Allocator, building_id: BuildingId) !bool {
        if (self.get_building_role(building_id) == .none) return true;

        const endpoint: energy.Endpoint = .{ .structure = building_id };
        var candidates = energy.EndpointList.init();
        const directions = [_]Direction{ .up, .down, .left, .right };

        for (self.structures.iter()) |structure| {
            if (structure.building_id == null or !sti.meta.eql(structure.building_id.?, building_id)) continue;

            for (directions) |dir| {
                var pos = structure.position;
                var step: usize = 0;
                while (step < energy.max_link_span) : (step += 1) {
                    pos = dir.pos_in_dir(pos);
                    const candidate = self.get_endpoint_at(pos) orelse continue;
                    if (candidate != .pole) break;
                    if (!energy.has_link(self, endpoint, candidate) and candidate.degree(self) < candidate.limit()) {
                        candidates.append_unique(candidate);
                    }
                    break;
                }
            }
        }

        var links = energy.EndpointList.init();
        const selection_limit = @min(@as(usize, 1), endpoint.limit() -| endpoint.degree(self));
        for (candidates.as_slice()) |candidate| {
            if (links.len >= selection_limit) break;

            var can_select = true;
            for (links.as_slice()) |existing| {
                if (energy.are_connected(self, existing, candidate)) {
                    can_select = false;
                    break;
                }
            }
            if (!can_select) continue;

            links.append_unique(candidate);
        }

        for (links.as_slice()) |candidate| {
            try self.energy_links.push(allocator, .{
                .a = endpoint,
                .b = candidate,
            });
        }

        return true;
    }

    pub fn remove_links_touching_building(self: *Self, building_id: BuildingId) void {
        self.remove_links_touching(.{ .structure = building_id });
    }

    pub fn get_placement_preview(self: *const Self, pos: TilePosition) energy.PlacementPreview {
        if (!self.can_build_at(pos, energy.allowed_tiles)) {
            return .{
                .can_place = false,
                .links = energy.EndpointList.init(),
            };
        }

        const pole_endpoint: energy.Endpoint = .{ .pole = pos };
        const directions = [_]Direction{ .up, .down, .left, .right };
        var candidates = energy.EndpointList.init();

        for (directions) |dir| {
            var scan_pos = pos;
            var step: usize = 0;
            while (step < energy.max_link_span) : (step += 1) {
                scan_pos = dir.pos_in_dir(scan_pos);
                const candidate = self.get_endpoint_at(scan_pos) orelse continue;
                if (!energy.has_link(self, pole_endpoint, candidate) and candidate.degree(self) < candidate.limit()) {
                    candidates.append_unique(candidate);
                }
                break;
            }
        }

        var links = energy.EndpointList.init();
        const selection_limit = @min(@as(usize, 2), pole_endpoint.limit() -| pole_endpoint.degree(self));
        for (candidates.as_slice()) |candidate| {
            if (links.len >= selection_limit) break;

            var can_select = true;
            for (links.as_slice()) |existing| {
                if (energy.are_connected(self, existing, candidate)) {
                    can_select = false;
                    break;
                }
            }
            if (!can_select) continue;

            links.append_unique(candidate);
        }

        return .{
            .can_place = true,
            .links = links,
        };
    }

    pub fn place_power_pole(self: *Self, allocator: Allocator, pos: TilePosition) !bool {
        const preview = self.get_placement_preview(pos);
        if (!preview.can_place) return false;

        try self.structures.add(allocator, .{
            .position = pos,
            .structure_type = .power_pole,
            .direction = null,
            .building_id = null,
        });

        const pole_endpoint: energy.Endpoint = .{ .pole = pos };
        for (preview.links.as_slice()) |other| {
            try self.energy_links.push(allocator, .{
                .a = pole_endpoint,
                .b = other,
            });
        }

        return true;
    }

    pub fn remove_power_pole(self: *Self, allocator: Allocator, pos: TilePosition) bool {
        const structure = self.structures.get_const(pos) orelse return false;
        if (structure.structure_type != .power_pole) return false;

        self.remove_links_touching(.{ .pole = pos });
        _ = self.structures.remove(allocator, pos);
        return true;
    }

    pub fn remove_links_touching(self: *Self, endpoint: energy.Endpoint) void {
        var index: usize = 0;
        while (index < self.energy_links.len()) {
            const link = self.energy_links.as_slice()[index];
            if (link.a.eql(endpoint) or link.b.eql(endpoint)) {
                _ = self.energy_links.swap_remove(index);
                continue;
            }
            index += 1;
        }
    }

    pub fn can_build_at(self: *const Self, pos: TilePosition, allowed_tiles: sti.EnumBitVector(TileTypes)) bool {
        if (self.structures.has_structure(pos)) return false;
        const tile = self.chunks.get_tile_const(pos) orelse return false;
        return allowed_tiles.has_tag(tile.tile_type);
    }

    pub fn can_place_structure(self: *Self, center: TilePosition, shape: *const card.StructureShape, allowed_tiles: sti.EnumBitVector(TileTypes)) bool {
        const shape_size = shape.size();
        const half: isize = @intCast(shape_size / 2);

        for (0..shape_size) |dy| {
            for (0..shape_size) |dx| {
                const shape_pos = card.ShapePos{ .data = .{ @intCast(dx), @intCast(dy) } };
                if (shape.get(shape_pos)) {
                    const offset_x: isize = @as(isize, @intCast(dx)) - half;
                    const offset_y: isize = @as(isize, @intCast(dy)) - half;
                    const tile_pos: TilePosition = .{
                        .data = .{ center.data[0] + offset_x, center.data[1] + offset_y },
                    };
                    if (!self.can_build_at(tile_pos, allowed_tiles)) return false;
                }
            }
        }
        return true;
    }

>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
    pub fn generate_map_around_position(self: *Self, allocator: Allocator, position: TilePosition, rng: *sti.Random) void {
        const chunk_position = position.to_chunk_and_subchunk_position().chunk_position;

        for (0..3) |x_offset| {
            for (0..3) |y_offset| {
                const x = chunk_position.data[0] + @as(isize, @intCast(x_offset)) - 1;
                const y = chunk_position.data[1] + @as(isize, @intCast(y_offset)) - 1;
                const current_chunk_position: ChunkPosition = .{ .data = .{ x, y } };
                if (!self.chunks.data.data.contains_key(current_chunk_position)) {
                    self.chunks.generate_chunk(
                        allocator,
                        current_chunk_position,
                        rng,
                    ) catch |err| sti.debug.panic("{}", .{err});
                }
            }
        }
    }
};
