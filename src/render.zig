const sti = @import("sti");
const debug = sti.debug;
const format = sti.format;

const rl = @import("raylib");

const game = @import("game.zig");
const map = @import("map.zig");
const camera = @import("camera.zig");
const ui = @import("ui.zig");
const control = @import("control.zig");
const card = @import("card.zig");
const player = @import("player.zig");
<<<<<<< HEAD
const format = @import("format.zig");
=======
const texture = @import("texture.zig");
const turn = @import("turn.zig");
const belt = @import("belt.zig");
const energy = @import("energy.zig");
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

const Allocator = sti.Memory.Allocator;

pub const WorldPosition = struct {
    const Self = @This();
    data: rl.Vector3,

    pub fn to_tile_position(self: Self) map.TilePosition {
        const size = TileRenderSettings.size;
        const offset = -@as(f32, map.ChunkSize) / 2.0 + size / 2.0;
        const x: i32 = @intFromFloat(@floor((self.data.x - offset) / size));
        const z: i32 = @intFromFloat(@floor((self.data.z - offset) / size));
        return .{ .data = .{ x, z } };
    }
};

pub const RenderState = struct {
    const Self = @This();
    camera: camera.Camera,
    debug_ui: ui.DebugUI,
<<<<<<< HEAD
    ui_state: ui.UIState,
    tile_atlas: TileAtlas,
=======
    textures: texture.Textures,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

    pub const default: Self = .{
        .camera = .default,
        .debug_ui = .default,
<<<<<<< HEAD
        .ui_state = .default,
        .tile_atlas = undefined,
=======
        .textures = undefined,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
    };

    pub fn init(self: *Self) void {
        self.textures = texture.Textures.init();
    }
};
pub const RenderSettings = struct {
    pub const fps = 144;
};

pub const TileRenderSettings = struct {
    pub const size: f32 = 1.0;
};

pub const TileAtlas = struct {
    const Self = @This();
    const tile_type_count = @typeInfo(map.TileTypes).@"enum".fields.len;

    texture: rl.Texture2D,
    tile_models: [tile_type_count]rl.Model,

    pub fn init() Self {
        const texture = rl.loadTexture("textures/tiles.png") catch @panic("failed to load tile atlas");
        rl.setTextureFilter(texture, .point);

        var self: Self = .{
            .texture = texture,
            .tile_models = undefined,
        };

        inline for (0..tile_type_count) |i| {
            const tile_type: map.TileTypes = @enumFromInt(i);
            const uv = atlas_uv(tile_type);

            var mesh = rl.genMeshPlane(TileRenderSettings.size, TileRenderSettings.size, 1, 1);

            // remap uvs for the tile texture
            const vc: usize = @intCast(mesh.vertexCount);
            for (0..vc) |v| {
                const u = mesh.texcoords[v * 2 + 0];
                const vt = mesh.texcoords[v * 2 + 1];
                mesh.texcoords[v * 2 + 0] = uv.u_min + u * (uv.u_max - uv.u_min);
                mesh.texcoords[v * 2 + 1] = uv.v_min + vt * (uv.v_max - uv.v_min);
            }
            // sync data to GPU
            // index 1 = texcoords
            rl.updateMeshBuffer(mesh, 1, @ptrCast(mesh.texcoords), @intCast(vc * 2 * @sizeOf(f32)), 0);

            const model = rl.loadModelFromMesh(mesh) catch @panic("failed to create tile model");
            // idk if its neccesary buuuuut i don't like the idea of a raw ptrcast there
            const materials: [*]rl.Material = model.materials orelse @panic("model has null materials");
            rl.setMaterialTexture(&materials[0], .albedo, texture);
            self.tile_models[i] = model;
        }

        return self;
    }

    const AtlasUV = struct { u_min: f32, u_max: f32, v_min: f32, v_max: f32 };

    // 2x2 grid of 32x32 textures
    fn atlas_uv(tile_type: map.TileTypes) AtlasUV {
        return switch (tile_type) {
            .stone => .{ .u_min = 0.0, .u_max = 0.5, .v_min = 0.0, .v_max = 0.5 },
            .lava => .{ .u_min = 0.5, .u_max = 1.0, .v_min = 0.0, .v_max = 0.5 },
        };
    }

    pub fn draw_tile(self: Self, tile_type: map.TileTypes, position: rl.Vector3) void {
        self.tile_models[@intFromEnum(tile_type)].draw(position, 1.0, rl.Color.white);
    }

    pub fn deinit(self: *Self) void {
        for (&self.tile_models) |*model| {
            model.unload();
        }
        self.texture.unload();
    }
};

pub fn lerp(a: f64, b: f64, t: f64) f64 {
    return a * (1.0 - t) + (b * t);
}

pub fn lerp3d(a: WorldPosition, b: WorldPosition, t: f64) WorldPosition {
    const a_ = a.data;
    const b_ = b.data;
    return .{ .data = .{
        .x = @floatCast(lerp(a_.x, b_.x, t)),
        .y = @floatCast(lerp(a_.y, b_.y, t)),
        .z = @floatCast(lerp(a_.z, b_.z, t)),
    } };
}

pub fn render(
    allocator: Allocator,
    rs: *RenderState,
    cs: *control.ControlState,
    tilemap: *map.Map,
    p: *player.Player,
<<<<<<< HEAD
=======
    ts: *turn.TurnState,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
    dt: u64,
) !void {
    const local_camera = &rs.camera;

    local_camera.process(dt);

    rl.beginDrawing();
    defer rl.endDrawing();
    rl.clearBackground(rl.Color.black);

    //3D Mode
    {
        rl.beginMode3D(local_camera.to_rl_camera());
        defer rl.endMode3D();

        switch (cs.mode) {
            .game => {
<<<<<<< HEAD
                try render_map(local_camera, tilemap, rs.tile_atlas);
=======
                try render_map(local_camera, tilemap, rs.textures.tile_atlas);
                render_energy_links(tilemap);
                render_structures(&tilemap.structures, rs.textures.structures, rs.textures.belts, rs.textures.power_pole);
                render_placement_preview(cs, tilemap, p);
                render_belt_mode_preview(cs, tilemap);
                render_energy_mode_preview(cs, tilemap);
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
            },
            .menu => {
                //No drawing because RL is still in 3D mode.
            },
        }
    }
    //UI
    {
<<<<<<< HEAD
        if (cs.mode == .menu) {
            try render_menu(allocator, us);
        }
        try render_player(allocator, p, cs);
        try rs.debug_ui.draw(allocator, cs, local_camera, tilemap);
=======
        try render_player(allocator, rs, p, cs, ts);
        render_toolbar(cs);
        try rs.debug_ui.draw(allocator, cs, local_camera, tilemap, ts);
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
    }
}

const Length = ui.Length;

pub const EndTurnButtonSettings = struct {
    const height: Length = 80;
    const margin: Length = 32;

    // width depends on texture aspect ratio so computed at runtime, but in base 1080p units
    pub fn get_rect(tex: rl.Texture2D) ui.Rectangle {
        const aspect: f64 = @as(f64, @floatFromInt(tex.width)) / @as(f64, @floatFromInt(tex.height));
        const w: Length = @intFromFloat(@as(f64, @floatFromInt(height)) * aspect);
        return .{
            .position = .{ .x = 1920 - w - margin, .y = 1080 - height - margin },
            .size = .{ .width = w, .height = height },
        };
    }
};

pub const ToolbarSettings = struct {
    const size: Length = 64;
    const margin: Length = 16;
    const gap: Length = 8;
    const hud_gap: Length = 16;

    pub fn get_button_rect(index: Length) ui.Rectangle {
        return .{
            .position = .{ .x = margin, .y = 540 - size + index * (size + gap) },
            .size = .{ .width = size, .height = size },
        };
    }

<<<<<<< HEAD
    // Build string and draw every frame
    var string: sti.ArrayList(u8) = .init();
    defer string.deinit(allocator);
    try format.append_fmt(allocator, &string, "test\n", .{});
    try string.push(allocator, 0);
    const c_string: [:0]const u8 = @ptrCast(string.as_slice());
=======
    pub fn get_right_edge() Length {
        return margin + size;
    }
};

pub const CardRenderSettings = struct {
    const bg_color = rl.Color.dark_gray;
    const border_color = rl.Color.light_gray;
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

    pub const width: Length = 200;
    pub const height: Length = 260;
    pub const gap: Length = 16;
    pub const bottom_margin: Length = 32;
    pub const padding: Length = 16;

    const cost_font_size: Length = 30;
    const name_font_size: Length = 26;
    const effect_font_size: Length = 18;

    const text_width: Length = width - padding * 2;
    const cost_y: Length = padding;
    const name_y: Length = cost_y + cost_font_size + padding;
    const effect_y: Length = name_y + name_font_size + padding;
    const hover_grow: Length = 16;
    const glow_size: Length = 4;
    const effect_height: Length = height - effect_y - padding;
};

// base_x and base_y are in base 1080p coordinates
fn render_card(c: card.CardEnum, base_x: u32, base_y: u32, hovered: bool, player_energy: u32) void {
    const S = CardRenderSettings;
    const card_data = card.get(c);

    const x = if (hovered) base_x - S.hover_grow / 2 else base_x;
    const y = if (hovered) base_y - S.hover_grow else base_y;
    const cw = if (hovered) S.width + S.hover_grow else S.width;
    const ch = if (hovered) S.height + S.hover_grow else S.height;

    if (hovered) {
        rl.drawRectangle(
            format.scale(x - S.glow_size),
            format.scale(y - S.glow_size),
            format.scale(cw + S.glow_size * 2),
            format.scale(ch + S.glow_size * 2),
            rl.Color.gold,
        );
    }

    rl.drawRectangle(format.scale(x), format.scale(y), format.scale(cw), format.scale(ch), S.bg_color);
    rl.drawRectangleLines(format.scale(x), format.scale(y), format.scale(cw), format.scale(ch), if (hovered) rl.Color.gold else S.border_color);

    // energy cost (runtime value)
    const has_energy = player_energy >= card_data.energy_cost;
    const cost_color = if (has_energy) rl.Color.yellow else rl.Color.red;
    var cost_buf: [16]u8 = undefined;
    const cost_str = sti.format.buf_print(&cost_buf, "{d}", .{card_data.energy_cost}) catch unreachable;
    cost_buf[cost_str.len] = 0;
    rl.drawText(@ptrCast(cost_buf[0..cost_str.len :0]), format.scale(x + S.padding), format.scale(y + S.cost_y), format.scale(S.cost_font_size), cost_color);

    const name_box = ui.TextBox{
        .text = card_data.name,
        .rect = .{ .position = .{ .x = x + S.padding, .y = y + S.name_y }, .size = .{ .width = S.text_width, .height = S.name_font_size } },
        .margin = .zero,
        .font_size = S.name_font_size,
        .color = rl.Color.white,
        .justification = .left,
        .line_gap = 2,
    };
    const effect_box = ui.TextBox{
        .text = card_data.effect_text,
        .rect = .{ .position = .{ .x = x + S.padding, .y = y + S.effect_y }, .size = .{ .width = S.text_width, .height = S.effect_height } },
        .margin = .zero,
        .font_size = S.effect_font_size,
        .color = rl.Color.light_gray,
        .justification = .left,
        .line_gap = 2,
    };
    name_box.draw();
    effect_box.draw();
}

fn render_player(allocator: Allocator, rs: *RenderState, p: *player.Player, cs: *control.ControlState, ts: *turn.TurnState) !void {
    render_hand(&p.hand, cs, p.energy);
    try render_deck(allocator, &p.deck);
    try render_energy(allocator, p);
    render_end_turn_button(rs, ts);
}

// all layout computed in base 1080p (1920x1080)
fn render_hand(hand: *card.Hand, cs: *control.ControlState, player_energy: u32) void {
    const S = CardRenderSettings;
    const count: u32 = @intCast(hand.count);
    const total_width = count * S.width + (count -| 1) * S.gap;
    const start_x = (1920 - total_width) / 2;
    const y = 1080 - S.height - S.bottom_margin;

    for (0..hand.count) |i| {
        if (hand.cards[i]) |c| {
            const x = start_x + @as(u32, @intCast(i)) * (S.width + S.gap);
            const placing = if (cs.placement_mode) |pm| pm.card_index == i else false;
            const hovered = placing or if (cs.hovered) |h| h.is_card(i) else false;
            render_card(c, x, y, hovered, player_energy);
        }
    }
}

fn render_deck(allocator: Allocator, deck: *card.Deck) !void {
    const S = CardRenderSettings;
    const screen_width = rl.getScreenWidth();
    const screen_height = rl.getScreenHeight();
    const ch = format.scale(S.height);
    const pad = format.scale(S.padding);
    const deck_fs = format.scale(S.cost_font_size);
    const y = screen_height - ch - format.scale(S.bottom_margin);

    var deck_buf: sti.ArrayList(u8) = .init();
    defer deck_buf.deinit(allocator);
    try format.append_fmt(allocator, &deck_buf, "Deck: {d}", .{deck.len()});
    try deck_buf.push(allocator, 0);
    const deck_str: [:0]const u8 = @ptrCast(deck_buf.as_slice());
    const deck_text_width = rl.measureText(deck_str, deck_fs);
    rl.drawText(
        deck_str,
        screen_width - deck_text_width - pad,
        y - deck_fs - pad,
        deck_fs,
        rl.Color.white,
    );
}

fn render_energy(allocator: Allocator, p: *player.Player) !void {
    const S = CardRenderSettings;
    const screen_height = rl.getScreenHeight();
    const ch = format.scale(S.height);
    const energy_fs = format.scale(S.cost_font_size);
    const y = screen_height - ch - format.scale(S.bottom_margin);
    const x = format.scale(ToolbarSettings.get_right_edge() + ToolbarSettings.hud_gap);

    var energy_buf: sti.ArrayList(u8) = .init();
    defer energy_buf.deinit(allocator);
    try format.append_fmt(allocator, &energy_buf, "Energy: {d}", .{p.energy});
    try energy_buf.push(allocator, 0);
    const energy_str: [:0]const u8 = @ptrCast(energy_buf.as_slice());
    rl.drawText(
        energy_str,
        x,
        y - energy_fs - format.scale(S.padding),
        energy_fs,
        rl.Color.yellow,
    );
}

fn render_end_turn_button(rs: *RenderState, ts: *turn.TurnState) void {
    const button = get_end_turn_button(rs.textures.end_turn);
    button.draw(ts.phase == .play);
}

pub fn get_end_turn_button(tex: rl.Texture2D) ui.Button {
    return .{
        .rect = EndTurnButtonSettings.get_rect(tex),
        .margin = .zero,
        .content = .{ .texture = tex },
        .normal_color = rl.Color.white,
        .hovered_color = rl.Color.light_gray,
        .active_color = rl.Color.white,
    };
}

fn render_belt_mode_preview(cs: *control.ControlState, tilemap: *map.Map) void {
    const belt_mode = cs.belt_tool.mode orelse return;
    const pos = cs.belt_tool.hovered_tile orelse return;

    // don't show if hovering any ui element
    if (cs.hovered != null) return;

    const tile_size = TileRenderSettings.size;
    const world_pos = pos.to_world_position().data;

    switch (belt_mode) {
        .place => {
            const color = if (tilemap.can_build_at(pos, belt.BeltSettings.allowed_tiles)) rl.Color.green else rl.Color.red;

            // draw tile outline
            rl.drawCubeWires(
                .{ .x = world_pos.x, .y = 0.05, .z = world_pos.z },
                tile_size,
                0.1,
                tile_size,
                color,
            );

            // draw direction arrow
            const arrow_len = tile_size * 0.4;
            const arrow_start: rl.Vector3 = .{ .x = world_pos.x, .y = 0.2, .z = world_pos.z };
            const arrow_end: rl.Vector3 = switch (cs.belt_tool.rotation) {
                .up => .{ .x = world_pos.x, .y = 0.2, .z = world_pos.z - arrow_len },
                .down => .{ .x = world_pos.x, .y = 0.2, .z = world_pos.z + arrow_len },
                .left => .{ .x = world_pos.x - arrow_len, .y = 0.2, .z = world_pos.z },
                .right => .{ .x = world_pos.x + arrow_len, .y = 0.2, .z = world_pos.z },
            };
            rl.drawLine3D(arrow_start, arrow_end, rl.Color.yellow);
        },
        .remove => {
            // check if there's a belt to remove
            var can_remove = false;
            if (tilemap.structures.get(pos)) |structure| {
                can_remove = structure.structure_type == .belt;
            }
            const color = if (can_remove) rl.Color.red else rl.Color.gray;

            rl.drawCubeWires(
                .{ .x = world_pos.x, .y = 0.05, .z = world_pos.z },
                tile_size,
                0.1,
                tile_size,
                color,
            );
        },
    }
}

fn render_toolbar(cs: *control.ControlState) void {
    const place_button = get_belt_place_button();
    const remove_button = get_belt_remove_button();
    const energy_place_button = get_energy_place_button();
    const energy_remove_button = get_energy_remove_button();

    place_button.draw(cs.belt_tool.mode == .place);
    remove_button.draw(cs.belt_tool.mode == .remove);
    energy_place_button.draw(cs.energy_tool.mode == .place);
    energy_remove_button.draw(cs.energy_tool.mode == .remove);
}

pub fn get_belt_place_button() ui.Button {
    const rect = ToolbarSettings.get_button_rect(0);
    return .{
        .rect = rect,
        .margin = .zero,
        .content = .{ .text = .{
            .text_box = .{
                .text = "B+",
                .rect = rect,
                .margin = .zero,
                .font_size = ToolbarSettings.size / 2,
                .color = rl.Color.white,
                .justification = .center,
                .line_gap = 0,
            },
            .alignment = .{ .horizontal = .center, .vertical = .center },
        } },
        .normal_color = rl.Color.dark_gray,
        .hovered_color = rl.Color.light_gray,
        .active_color = rl.Color.green,
    };
}

pub fn get_belt_remove_button() ui.Button {
    const rect = ToolbarSettings.get_button_rect(1);
    return .{
        .rect = rect,
        .margin = .zero,
        .content = .{ .text = .{
            .text_box = .{
                .text = "B-",
                .rect = rect,
                .margin = .zero,
                .font_size = ToolbarSettings.size / 2,
                .color = rl.Color.white,
                .justification = .center,
                .line_gap = 0,
            },
            .alignment = .{ .horizontal = .center, .vertical = .center },
        } },
        .normal_color = rl.Color.dark_gray,
        .hovered_color = rl.Color.light_gray,
        .active_color = rl.Color.red,
    };
}

pub fn get_energy_place_button() ui.Button {
    const rect = ToolbarSettings.get_button_rect(2);
    return .{
        .rect = rect,
        .margin = .zero,
        .content = .{ .text = .{
            .text_box = .{
                .text = "P+",
                .rect = rect,
                .margin = .zero,
                .font_size = ToolbarSettings.size / 2,
                .color = rl.Color.white,
                .justification = .center,
                .line_gap = 0,
            },
            .alignment = .{ .horizontal = .center, .vertical = .center },
        } },
        .normal_color = rl.Color.dark_gray,
        .hovered_color = rl.Color.light_gray,
        .active_color = rl.Color.sky_blue,
    };
}

pub fn get_energy_remove_button() ui.Button {
    const rect = ToolbarSettings.get_button_rect(3);
    return .{
        .rect = rect,
        .margin = .zero,
        .content = .{ .text = .{
            .text_box = .{
                .text = "P-",
                .rect = rect,
                .margin = .zero,
                .font_size = ToolbarSettings.size / 2,
                .color = rl.Color.white,
                .justification = .center,
                .line_gap = 0,
            },
            .alignment = .{ .horizontal = .center, .vertical = .center },
        } },
        .normal_color = rl.Color.dark_gray,
        .hovered_color = rl.Color.light_gray,
        .active_color = rl.Color.red,
    };
}

fn render_energy_mode_preview(cs: *control.ControlState, tilemap: *map.Map) void {
    const mode = cs.energy_tool.mode orelse return;
    const pos = cs.energy_tool.hovered_tile orelse return;

    if (cs.hovered != null) return;

    const world_pos = pos.to_world_position().data;

    switch (mode) {
        .place => {
            const preview = tilemap.get_placement_preview(pos);
            const color = if (preview.can_place) rl.Color.green else rl.Color.red;

            rl.drawCubeWires(
                .{ .x = world_pos.x, .y = 0.05, .z = world_pos.z },
                TileRenderSettings.size,
                0.1,
                TileRenderSettings.size,
                color,
            );

            const start: rl.Vector3 = .{ .x = world_pos.x, .y = 0.85, .z = world_pos.z };
            for (preview.links.as_slice()) |endpoint| {
                const end = get_energy_link_endpoint_world_position(tilemap, endpoint, .{ .pole = pos });
                rl.drawLine3D(start, end, if (preview.can_place) rl.Color.sky_blue else rl.Color.red);
            }
        },
        .remove => {
            var can_remove = false;
            if (tilemap.structures.get_const(pos)) |structure| {
                can_remove = structure.structure_type == .power_pole;
            }
            rl.drawCubeWires(
                .{ .x = world_pos.x, .y = 0.05, .z = world_pos.z },
                TileRenderSettings.size,
                0.1,
                TileRenderSettings.size,
                if (can_remove) rl.Color.red else rl.Color.gray,
            );
        },
    }
}

fn render_placement_preview(cs: *control.ControlState, tilemap: *map.Map, p: *player.Player) void {
    const pm = cs.placement_mode orelse return;
    const center = pm.hovered_tile orelse return;

    // don't show preview if hovering any ui element
    if (cs.hovered != null) return;

    // don't show preview if not enough energy
    const cost = card.get(pm.c).energy_cost;
    if (p.energy < cost) return;

    const shape_size = pm.shape.size();
    const half: isize = @intCast(shape_size / 2);
    const tile_size = TileRenderSettings.size;
    const places_tiles = card.is_tile_card(pm.c);

    const allowed_tiles = card.get(pm.c).card_type.factory.allowed_tiles;

    // for structures, check whole shape validity upfront
    const structure_valid = places_tiles or tilemap.can_place_structure(center, &pm.shape, allowed_tiles);

    // for tile cards, check if any tile in the shape covers lava
    const has_any_lava = if (places_tiles) blk: {
        for (0..shape_size) |dy| {
            for (0..shape_size) |dx| {
                const sp = card.ShapePos{ .data = .{ @intCast(dx), @intCast(dy) } };
                if (pm.shape.get(sp)) {
                    const ox: isize = @as(isize, @intCast(dx)) - half;
                    const oy: isize = @as(isize, @intCast(dy)) - half;
                    const tp: map.TilePosition = .{ .data = .{ center.data[0] + ox, center.data[1] + oy } };
                    const tile = tilemap.chunks.get_tile(tp) orelse continue;
                    if (tile.tile_type == .lava) break :blk true;
                }
            }
        }
        break :blk false;
    } else false;

    for (0..shape_size) |dy| {
        for (0..shape_size) |dx| {
            const shape_pos = card.ShapePos{ .data = .{ @intCast(dx), @intCast(dy) } };
            if (pm.shape.get(shape_pos)) {
                const offset_x: isize = @as(isize, @intCast(dx)) - half;
                const offset_y: isize = @as(isize, @intCast(dy)) - half;
                const tile_pos: map.TilePosition = .{
                    .data = .{ center.data[0] + offset_x, center.data[1] + offset_y },
                };
                const world_pos = tile_pos.to_world_position().data;

                const color = if (places_tiles) blk: {
                    if (!has_any_lava) break :blk rl.Color.red;
                    const tile = tilemap.chunks.get_tile(tile_pos) orelse break :blk rl.Color.red;
                    break :blk switch (tile.tile_type) {
                        .lava => rl.Color.green,
                        .stone, .metal => rl.Color.orange,
                    };
                } else if (structure_valid) rl.Color.green else rl.Color.red;

                rl.drawCubeWires(
                    .{ .x = world_pos.x, .y = 0.05, .z = world_pos.z },
                    tile_size,
                    0.1,
                    tile_size,
                    color,
                );
            }
        }
    }
}

pub const CardRenderSettings = struct {
    const bg_color = rl.Color.dark_gray;
    const border_color = rl.Color.light_gray;

    fn scale(base: f32) i32 {
        const screen_h: f32 = @floatFromInt(rl.getScreenHeight());
        return @intFromFloat(@round(base * screen_h / 1080.0));
    }

    pub fn card_width() i32 {
        return scale(200);
    }
    pub fn card_height() i32 {
        return scale(260);
    }
    pub fn card_gap() i32 {
        return scale(16);
    }
    pub fn bottom_margin() i32 {
        return scale(32);
    }
    pub fn padding() i32 {
        return scale(16);
    }
    pub fn name_font_size() i32 {
        return scale(26);
    }
    pub fn cost_font_size() i32 {
        return scale(30);
    }
    pub fn effect_font_size() i32 {
        return scale(18);
    }
    pub fn flavour_font_size() i32 {
        return scale(14);
    }
    pub fn line_spacing() i32 {
        return scale(2);
    }
};

fn render_card(allocator: Allocator, c: card.Card, base_x: i32, base_y: i32, hovered: bool) !void {
    const hover_grow = CardRenderSettings.scale(16);
    const glow_size = CardRenderSettings.scale(4);

    const cw = if (hovered) CardRenderSettings.card_width() + hover_grow else CardRenderSettings.card_width();
    const ch = if (hovered) CardRenderSettings.card_height() + hover_grow else CardRenderSettings.card_height();
    const x = if (hovered) base_x - @divTrunc(hover_grow, 2) else base_x;
    const y = if (hovered) base_y - hover_grow else base_y;

    const pad = CardRenderSettings.padding();
    const cost_fs = CardRenderSettings.cost_font_size();
    const name_fs = CardRenderSettings.name_font_size();
    const effect_fs = CardRenderSettings.effect_font_size();

    // Glow border when hovered
    if (hovered) {
        rl.drawRectangle(x - glow_size, y - glow_size, cw + glow_size * 2, ch + glow_size * 2, rl.Color.gold);
    }

    // Card background
    rl.drawRectangle(x, y, cw, ch, CardRenderSettings.bg_color);
    // Card border
    rl.drawRectangleLines(x, y, cw, ch, if (hovered) rl.Color.gold else CardRenderSettings.border_color);

    // Energy cost
    var cost_buf: sti.ArrayList(u8) = .init();
    defer cost_buf.deinit(allocator);
    try format.append_fmt(allocator, &cost_buf, "{d}\n", .{c.energy_cost});
    try cost_buf.push(allocator, 0);
    const cost_str: [:0]const u8 = @ptrCast(cost_buf.as_slice());
    rl.drawText(cost_str, x + pad, y + pad, cost_fs, rl.Color.yellow);

    // Card name
    rl.drawText(@ptrCast(c.name), x + pad, y + pad + cost_fs + pad, name_fs, rl.Color.white);

    // Effect text wrapped
    const max_width = cw - pad * 2;
    const ls = CardRenderSettings.line_spacing();
    const effect_y = y + pad + cost_fs + pad + name_fs + pad;
    _ = try format.draw_wrapped_text(allocator, c.effect_text, x + pad, effect_y, effect_fs, max_width, ls, rl.Color.light_gray);

    // Flavour text wrapped at the bottom
    const flavour_fs = CardRenderSettings.flavour_font_size();
    const flavour_lines = try format.count_wrapped_lines(allocator, c.flavour_text, flavour_fs, max_width);
    const flavour_y = y + ch - pad - @as(i32, @intCast(flavour_lines)) * (flavour_fs + ls);
    _ = try format.draw_wrapped_text(allocator, c.flavour_text, x + pad, flavour_y, flavour_fs, max_width, ls, rl.Color.gray);
}

fn render_player(allocator: Allocator, p: *player.Player, cs: *control.ControlState) !void {
    try render_hand(allocator, &p.hand, cs);
    try render_deck(allocator, &p.deck);
}

fn render_hand(allocator: Allocator, hand: *card.Hand, cs: *control.ControlState) !void {
    const screen_width = rl.getScreenWidth();
    const screen_height = rl.getScreenHeight();
    const count: i32 = @intCast(hand.count);
    const cw = CardRenderSettings.card_width();
    const ch = CardRenderSettings.card_height();
    const gap = CardRenderSettings.card_gap();

    const total_width = count * cw + (count - 1) * gap;
    const start_x = @divTrunc(screen_width - total_width, 2);
    const y = screen_height - ch - CardRenderSettings.bottom_margin();

    for (0..hand.count) |i| {
        if (hand.cards[i]) |c| {
            const x = start_x + @as(i32, @intCast(i)) * (cw + gap);
            const hovered = cs.hovered_card != null and cs.hovered_card.? == i;
            try render_card(allocator, c, x, y, hovered);
        }
    }
}

fn render_deck(allocator: Allocator, deck: *card.Deck) !void {
    const screen_width = rl.getScreenWidth();
    const screen_height = rl.getScreenHeight();
    const ch = CardRenderSettings.card_height();
    const pad = CardRenderSettings.padding();
    const deck_fs = CardRenderSettings.cost_font_size();
    const y = screen_height - ch - CardRenderSettings.bottom_margin();

    var deck_buf: sti.ArrayList(u8) = .init();
    defer deck_buf.deinit(allocator);
    try format.append_fmt(allocator, &deck_buf, "Deck: {d}", .{deck.len()});
    try deck_buf.push(allocator, 0);
    const deck_str: [:0]const u8 = @ptrCast(deck_buf.as_slice());
    const deck_text_width = rl.measureText(deck_str, deck_fs);
    rl.drawText(
        deck_str,
        screen_width - deck_text_width - pad,
        y - deck_fs - pad,
        deck_fs,
        rl.Color.white,
    );
}

const WireRenderSettings = struct {
    const size = TileRenderSettings.size / 4;
    const offset = TileRenderSettings.size / 4;
};

<<<<<<< HEAD
fn render_tile(atlas: TileAtlas, position: map.TilePosition, tile: map.Tile) void {
    var tile_pos = position.to_world_position().data;
    tile_pos.y = 0;
    atlas.draw_tile(tile.tile_type, tile_pos);
=======
fn render_tile(atlas: texture.TileAtlas, position: map.TilePosition, tile: map.Tile) void {
    var tile_pos = position.to_world_position().data;
    tile_pos.y = 0;
    atlas.draw_tile(tile.tile_type, tile_pos);
}

fn render_structures(structures: *const map.Structures, structure_textures: texture.StructureTextures, belt_textures: texture.BeltTextures, power_pole_model: rl.Model) void {
    const size = TileRenderSettings.size;
    for (structures.iter()) |structure| {
        var pos = structure.position.to_world_position().data;

        switch (structure.structure_type) {
            .belt => {
                pos.y = size * 0.25;
                const direction = structure.direction orelse .up;
                const shape = belt.compute_shape(structures, structure.position, direction);
                const model = belt_textures.get_model(shape);

                const rotation_angle: f32 = switch (direction) {
                    .up => 0,
                    .right => 270,
                    .down => 180,
                    .left => 90,
                };

                model.drawEx(pos, .{ .x = 0, .y = 1, .z = 0 }, rotation_angle, .{ .x = 1, .y = 1, .z = 1 }, rl.Color.white);
            },
            .card => |card_type| {
                pos.y = size / 2;
                const model = structure_textures.get_model(card_type);
                model.draw(pos, 1.0, rl.Color.white);
            },
            .power_pole => {
                pos.y = size * 0.45;
                power_pole_model.draw(pos, 1.0, rl.Color.white);
            },
        }
    }
}

fn get_energy_link_endpoint_world_position(tilemap: *map.Map, endpoint: energy.Endpoint, other_endpoint: energy.Endpoint) rl.Vector3 {
    var pos = tilemap.get_render_endpoint_tile(endpoint, other_endpoint).to_world_position().data;
    pos.y = switch (endpoint) {
        .pole => TileRenderSettings.size * 0.85,
        .structure => TileRenderSettings.size * 1.05,
    };
    return pos;
}

fn render_energy_links(tilemap: *map.Map) void {
    for (tilemap.energy_links.as_slice()) |link| {
        const start = get_energy_link_endpoint_world_position(tilemap, link.a, link.b);
        const end = get_energy_link_endpoint_world_position(tilemap, link.b, link.a);
        rl.drawLine3D(start, end, rl.Color.sky_blue);
    }
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
}

fn render_map(
    local_camera: *camera.Camera,
    tilemap: *map.Map,
<<<<<<< HEAD
    atlas: TileAtlas,
=======
    atlas: texture.TileAtlas,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
) !void {
    {
        const camera_position = local_camera.current_position().to_tile_position();

        //Render tilemap around around camera focus
        const camera_chunk_position = camera_position.to_chunk_and_subchunk_position().chunk_position;
        for (0..3) |x_offset| {
            for (0..3) |y_offset| {
                const x = camera_chunk_position.data[0] + @as(isize, @intCast(x_offset)) - 1;
                const y = camera_chunk_position.data[1] + @as(isize, @intCast(y_offset)) - 1;
                const chunk_position: map.ChunkPosition = .{ .data = .{ x, y } };

                if (tilemap.chunks.data.data.get(chunk_position)) |map_data| {
                    for (map_data.tiles.storage, 0..) |tile, i| {
                        const tile_position = chunk_position.to_tile_position(map_data.tiles.from_linear_index(i));
                        render_tile(atlas, tile_position, tile);
                    }
                }
            }
        }

        rl.drawSphere(
            camera_position.to_world_position().data,
            TileRenderSettings.size / 4,
            rl.Color.yellow,
        );
    }
}
