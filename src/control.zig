const sti = @import("sti");
const rl = @import("raylib");

const game = @import("game.zig");
const map = @import("map.zig");
const camera = @import("camera.zig");
const render = @import("render.zig");
const card = @import("card.zig");
<<<<<<< HEAD
=======
const player = @import("player.zig");
const turn = @import("turn.zig");
const belt = @import("belt.zig");
const energy = @import("energy.zig");
const ui = @import("ui.zig");
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

const Timestamp = u64;

pub const KeyboardKey = rl.KeyboardKey;

const wasd_keys = [_]KeyboardKey{
    .w,
    .a,
    .s,
    .d,
};
const arrow_keys = [_]KeyboardKey{
    .up,
    .left,
    .down,
    .right,
};

pub const GameMode = enum {
    menu,
    game,
};

pub const ControlState = struct {
    const Self = @This();
    const key_repeat_interval: comptime_int = 200_000_000;

    mode: GameMode,
    move_dir: ?map.Direction,
    move_cooldown: Timestamp,

<<<<<<< HEAD
    hovered_card: ?usize,
    clicked_card: ?usize,
=======
    hovered: ?ui.UIElement,
    card_state: CardState,
    placement_mode: ?PlacementState,
    belt_tool: belt.ToolState,
    energy_tool: energy.ToolState,

    pub const CardState = struct {
        clicked: ?usize,
    };

    pub const PlacementState = struct {
        card_index: usize,
        c: card.CardEnum,
        shape: card.StructureShape,
        hovered_tile: ?map.TilePosition,
    };
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

    pub const default = Self{
        .mode = .game,
        .move_dir = null,
        .move_cooldown = 0,
<<<<<<< HEAD
        .hovered_card = null,
        .clicked_card = null,
=======
        .hovered = null,
        .card_state = .{ .clicked = null },
        .placement_mode = null,
        .belt_tool = belt.ToolState.default,
        .energy_tool = energy.ToolState.default,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
    };

    pub fn tick_cooldown(self: *Self, dt: Timestamp) void {
        switch (comptime @typeInfo(Timestamp)) {
            .int => |info| {
                self.move_cooldown -|= dt;
                if ((comptime info.signedness == .signed) and self.move_cooldown < 0) {
                    self.move_cooldown = 0;
                }
            },
            else => @compileError("expected integer timestamp"),
        }
    }

    pub fn process_mode_input(self: *Self) void {
        const DEBUG = comptime false;
        if (rl.isKeyPressed(.tab)) {
            const enum_int: usize = @intFromEnum(self.mode);
            if (DEBUG) sti.debug.print("{}\n", .{enum_int});
            const tpinfo = @typeInfo(@TypeOf(self.mode)).@"enum";
            self.mode = @enumFromInt(@as(tpinfo.tag_type, @intCast((enum_int + 1) % tpinfo.fields.len)));
        }
    }

    pub fn process_movement_input(self: *Self) ?map.Direction {
        // keep moving in the direction you were originally moving even if you press other keys
        if (self.move_dir) |move_dir| {
            const dir_int = @intFromEnum(move_dir);
            if (rl.isKeyDown(wasd_keys[dir_int]) or rl.isKeyDown(arrow_keys[dir_int])) {
                if (self.move_cooldown > 0) {
                    return null;
                }
                self.move_cooldown = Self.key_repeat_interval;
                return move_dir;
            }

            self.move_dir = null;
        }

        // if no previous direction, pick any new direction
        inline for (0..4) |dir_int| {
            if (rl.isKeyDown(wasd_keys[dir_int]) or rl.isKeyDown(arrow_keys[dir_int])) {
                if (self.move_cooldown > 0) {
                    return null;
                }
                self.move_cooldown = Self.key_repeat_interval;
                self.move_dir = @enumFromInt(dir_int);
                return @enumFromInt(dir_int);
            }
        }

        // if you release the keys it should reset the cooldown
        // instead of eating input
        self.move_cooldown = 0;
        return null;
    }

    pub fn process_camera_input(
        _: *Self,
        cam: *camera.Camera,
    ) void {
        if (rl.isMouseButtonDown(.middle)) {
            const mouse_delta = rl.getMouseDelta();
            cam.rotation += mouse_delta.x / 100;
        }
        cam.zoom += rl.getMouseWheelMove();
        cam.zoom = @max(cam.zoom, 1);
    }

    pub fn process_hand_input(self: *Self, hand: *card.Hand) void {
        const mouse_x = rl.getMouseX();
        const mouse_y = rl.getMouseY();
        const screen_width = rl.getScreenWidth();
        const screen_height = rl.getScreenHeight();
<<<<<<< HEAD
        const cw = render.CardRenderSettings.card_width();
        const ch = render.CardRenderSettings.card_height();
        const gap = render.CardRenderSettings.card_gap();
=======
        const S = render.CardRenderSettings;
        const cw = sti.format.scale(S.width);
        const ch = sti.format.scale(S.height);
        const gap = sti.format.scale(S.gap);
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
        const count: i32 = @intCast(hand.count);

        const total_width = count * cw + (count - 1) * gap;
        const start_x = @divTrunc(screen_width - total_width, 2);
<<<<<<< HEAD
        const y = screen_height - ch - render.CardRenderSettings.bottom_margin();

        self.hovered_card = null;
        self.clicked_card = null;
=======
        const y = screen_height - ch - sti.format.scale(S.bottom_margin);

        self.card_state.clicked = null;
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

        for (0..hand.count) |i| {
            if (hand.cards[i] != null) {
                const x = start_x + @as(i32, @intCast(i)) * (cw + gap);
                if (mouse_x >= x and mouse_x <= x + cw and mouse_y >= y and mouse_y <= y + ch) {
<<<<<<< HEAD
                    self.hovered_card = i;
                    if (rl.isMouseButtonPressed(.left)) {
                        self.clicked_card = i;
=======
                    self.hovered = .{ .card = i };
                    if (rl.isMouseButtonPressed(.left)) {
                        self.card_state.clicked = i;
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
                    }
                    break;
                }
            }
<<<<<<< HEAD
=======
        }

        if (self.card_state.clicked) |idx| {
            if (hand.cards[idx]) |c| {
                const card_data = card.get(c);
                switch (card_data.card_type) {
                    .factory => |factory_data| {
                        if (factory_data.structure_shape) |shape| {
                            self.enter_placement_mode(idx, c, shape);
                        } else {
                            sti.debug.print("Card clicked: {s}\n", .{card_data.name});
                        }
                    },
                    .material => {
                        sti.debug.print("Card clicked: {s}\n", .{card_data.name});
                    },
                }
            }
        }
    }

    fn enter_placement_mode(self: *Self, idx: usize, c: card.CardEnum, shape: card.StructureShape) void {
        self.belt_tool.mode = null;
        self.energy_tool.mode = null;
        self.placement_mode = .{
            .card_index = idx,
            .c = c,
            .shape = shape,
            .hovered_tile = null,
        };
    }

    fn get_mouse_tile_position(cam: *camera.Camera) ?map.TilePosition {
        const mouse_pos = rl.getMousePosition();
        const rl_cam = cam.to_rl_camera();
        const ray = rl.getScreenToWorldRay(mouse_pos, rl_cam);

        if (ray.direction.y == 0) return null;

        const t = -ray.position.y / ray.direction.y;
        if (t < 0) return null;

        const half_tile = render.TileRenderSettings.size * 0.5;
        const world_pos: render.WorldPosition = .{ .data = .{
            .x = ray.position.x + t * ray.direction.x + half_tile,
            .y = 0,
            .z = ray.position.z + t * ray.direction.z + half_tile,
        } };

        return world_pos.to_tile_position();
    }

    pub fn process_end_turn_input(_: *Self, rs: *render.RenderState, ts: *turn.TurnState) void {
        if (ts.phase != .play) return;

        const button = render.get_end_turn_button(rs.textures.end_turn);
        if (button.is_clicked()) {
            ts.advance();
        }
    }

    pub fn process_placement_input(
        self: *Self,
        cam: *camera.Camera,
        tilemap: *map.Map,
        p: *player.Player,
        allocator: sti.Memory.Allocator,
    ) !void {
        if (self.placement_mode == null) return;
        var pm = &self.placement_mode.?;

        pm.hovered_tile = get_mouse_tile_position(cam);

        if (rl.isMouseButtonPressed(.right) or rl.isKeyPressed(.escape)) {
            self.placement_mode = null;
            return;
        }

        if (rl.isMouseButtonPressed(.left) and self.hovered == null) {
            if (pm.hovered_tile) |center| {
                const cost = card.get(pm.c).energy_cost;
                if (p.energy < cost) {
                    self.placement_mode = null;
                    return;
                }

                const shape_size = pm.shape.size();
                const half: isize = @intCast(shape_size / 2);
                const places_tiles = card.is_tile_card(pm.c);
                const power_role = card.get_power_role(pm.c);

                const allowed_tiles = card.get(pm.c).card_type.factory.allowed_tiles;

                // check if placement is valid
                if (places_tiles) {
                    // tile cards need at least one lava tile in the shape
                    var has_lava = false;
                    for (0..shape_size) |cy| {
                        for (0..shape_size) |cx| {
                            const sp = card.ShapePos{ .data = .{ @intCast(cx), @intCast(cy) } };
                            if (pm.shape.get(sp)) {
                                const ox: isize = @as(isize, @intCast(cx)) - half;
                                const oy: isize = @as(isize, @intCast(cy)) - half;
                                const tp: map.TilePosition = .{ .data = .{ center.data[0] + ox, center.data[1] + oy } };
                                const tile = tilemap.chunks.get_tile(tp) orelse continue;
                                if (tile.tile_type == .lava) {
                                    has_lava = true;
                                    break;
                                }
                            }
                        }
                        if (has_lava) break;
                    }
                    if (!has_lava) return;
                } else if (!tilemap.can_place_structure(center, &pm.shape, allowed_tiles)) {
                    return;
                }

                var structure_positions: [card.PatternShape.max_dim * card.PatternShape.max_dim]map.TilePosition = undefined;
                var structure_count: usize = 0;

                // Place structures or tiles
                for (0..shape_size) |dy| {
                    for (0..shape_size) |dx| {
                        const shape_pos = card.ShapePos{ .data = .{ @intCast(dx), @intCast(dy) } };
                        if (pm.shape.get(shape_pos)) {
                            const offset_x: isize = @as(isize, @intCast(dx)) - half;
                            const offset_y: isize = @as(isize, @intCast(dy)) - half;
                            const tile_pos: map.TilePosition = .{
                                .data = .{ center.data[0] + offset_x, center.data[1] + offset_y },
                            };

                            if (places_tiles) {
                                const tile = tilemap.chunks.get_tile(tile_pos) orelse continue;
                                if (tile.tile_type != .lava) continue;
                                tile.tile_type = .metal;
                            } else {
                                structure_positions[structure_count] = tile_pos;
                                structure_count += 1;
                            }
                        }
                    }
                }

                if (!places_tiles) {
                    const building_id = tilemap.allocate_building_id();
                    for (structure_positions[0..structure_count]) |tile_pos| {
                        try tilemap.structures.add(allocator, .{
                            .position = tile_pos,
                            .structure_type = .{ .card = pm.c },
                            .direction = null,
                            .building_id = building_id,
                        });
                    }

                    if (power_role != .none and !try tilemap.attach_building_endpoint(allocator, building_id)) {
                        for (structure_positions[0..structure_count]) |tile_pos| {
                            _ = tilemap.structures.remove(allocator, tile_pos);
                        }
                        return;
                    }
                }

                p.energy -= cost;
                _ = p.hand.remove(pm.card_index);
                self.placement_mode = null;
            }
        }
    }

    pub fn process_toolbar_input(self: *Self) void {
        const place_button = render.get_belt_place_button();
        if (place_button.is_hovered()) {
            self.hovered = .{ .toolbar = .belt_place };
            if (place_button.is_clicked()) {
                self.belt_tool.mode = if (self.belt_tool.mode == .place) null else .place;
                self.energy_tool.mode = null;
                self.placement_mode = null;
            }
        }

        const remove_button = render.get_belt_remove_button();
        if (remove_button.is_hovered()) {
            self.hovered = .{ .toolbar = .belt_remove };
            if (remove_button.is_clicked()) {
                self.belt_tool.mode = if (self.belt_tool.mode == .remove) null else .remove;
                self.energy_tool.mode = null;
                self.placement_mode = null;
            }
        }

        const energy_place_button = render.get_energy_place_button();
        if (energy_place_button.is_hovered()) {
            self.hovered = .{ .toolbar = .energy_place };
            if (energy_place_button.is_clicked()) {
                self.energy_tool.mode = if (self.energy_tool.mode == .place) null else .place;
                self.belt_tool.mode = null;
                self.placement_mode = null;
            }
        }

        const energy_remove_button = render.get_energy_remove_button();
        if (energy_remove_button.is_hovered()) {
            self.hovered = .{ .toolbar = .energy_remove };
            if (energy_remove_button.is_clicked()) {
                self.energy_tool.mode = if (self.energy_tool.mode == .remove) null else .remove;
                self.belt_tool.mode = null;
                self.placement_mode = null;
            }
        }
    }

    pub fn process_belt_mode_input(
        self: *Self,
        cam: *camera.Camera,
        tilemap: *map.Map,
        allocator: sti.Memory.Allocator,
    ) !void {
        if (self.belt_tool.mode == null) return;

        self.belt_tool.hovered_tile = get_mouse_tile_position(cam);

        // rotate with R key, alt+R for opposite direction
        if (rl.isKeyPressed(.r)) {
            if (rl.isKeyDown(.left_alt) or rl.isKeyDown(.right_alt)) {
                self.belt_tool.rotation = self.belt_tool.rotation.rotate(.left);
            } else {
                self.belt_tool.rotation = self.belt_tool.rotation.rotate(.right);
            }
        }

        // cancel with right-click or escape
        if (rl.isMouseButtonPressed(.right) or rl.isKeyPressed(.escape)) {
            self.belt_tool.mode = null;
            return;
        }

        // don't place/remove if hovering any ui element
        if (self.hovered != null) return;

        if (rl.isMouseButtonDown(.left)) {
            if (self.belt_tool.hovered_tile) |pos| {
                switch (self.belt_tool.mode.?) {
                    .place => {
                        // if there's already a belt, rotate it
                        if (tilemap.structures.get(pos)) |structure| {
                            if (structure.structure_type == .belt) {
                                structure.direction = self.belt_tool.rotation;
                                return;
                            }
                        }
                        // otherwise place new belt
                        if (tilemap.can_build_at(pos, belt.BeltSettings.allowed_tiles)) {
                            try tilemap.structures.add(allocator, .{
                                .position = pos,
                                .structure_type = .belt,
                                .direction = self.belt_tool.rotation,
                                .building_id = null,
                            });
                        }
                    },
                    .remove => {
                        // remove belt at position
                        if (tilemap.structures.get(pos)) |structure| {
                            if (structure.structure_type == .belt) {
                                _ = tilemap.structures.remove(allocator, pos);
                            }
                        }
                    },
                }
            }
        }
    }

    pub fn process_energy_mode_input(
        self: *Self,
        cam: *camera.Camera,
        tilemap: *map.Map,
        allocator: sti.Memory.Allocator,
    ) !void {
        if (self.energy_tool.mode == null) return;

        self.energy_tool.hovered_tile = get_mouse_tile_position(cam);

        if (rl.isMouseButtonPressed(.right) or rl.isKeyPressed(.escape)) {
            self.energy_tool.mode = null;
            return;
        }

        if (self.hovered != null) return;

        if (rl.isMouseButtonDown(.left)) {
            if (self.energy_tool.hovered_tile) |pos| {
                switch (self.energy_tool.mode.?) {
                    .place => {
                        _ = try tilemap.place_power_pole(allocator, pos);
                    },
                    .remove => {
                        _ = tilemap.remove_power_pole(allocator, pos);
                    },
                }
            }
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
        }

        if (self.clicked_card) |idx| {
            if (hand.cards[idx]) |c| {
                card_clicked(c);
            }
        }
    }

    fn card_clicked(c: card.Card) void {
        //todo actually make this build shit.
        debug.print("Card clicked: {s}\n", .{c.name});
    }

    pub fn process(
        self: *Self,
        rs: *render.RenderState,
        tilemap: *map.Map,
        hand: *card.Hand,
<<<<<<< HEAD
=======
        p: *player.Player,
        ts: *turn.TurnState,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
        allocator: sti.Memory.Allocator,
        rng: *sti.Random,
        dt: u64,
    ) !void {
        self.tick_cooldown(dt);
        self.hovered = null;
        self.process_mode_input();
        self.process_camera_input(&rs.camera);
<<<<<<< HEAD
        self.process_hand_input(hand);
=======
        self.process_toolbar_input();
        self.process_hand_input(hand);
        try self.process_placement_input(&rs.camera, tilemap, p, allocator);
        try self.process_belt_mode_input(&rs.camera, tilemap, allocator);
        try self.process_energy_mode_input(&rs.camera, tilemap, allocator);
        self.process_end_turn_input(rs, ts);
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

        if (self.process_movement_input()) |dir| {
            var tile_pos = rs.camera.current_position().to_tile_position();
            dir.move_from(&tile_pos);
            rs.camera.set_target(tile_pos.to_world_position());
            tilemap.generate_map_around_position(allocator, tile_pos, rng);
        }
    }
};
