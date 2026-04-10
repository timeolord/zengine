const rl = @import("raylib");
const map = @import("map.zig");
const render = @import("render.zig");
const card = @import("card.zig");
const belt = @import("belt.zig");

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

            var mesh = rl.genMeshPlane(render.TileRenderSettings.size, render.TileRenderSettings.size, 1, 1);

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
            const materials: [*]rl.Material = model.materials orelse @panic("model has null materials");
            rl.setMaterialTexture(&materials[0], .albedo, texture);
            self.tile_models[i] = model;
        }

        return self;
    }

    const AtlasUV = struct { u_min: f32, u_max: f32, v_min: f32, v_max: f32 };

    // 4x4 grid of 32x32 textures
    fn atlas_uv(tile_type: map.TileTypes) AtlasUV {
        const cell_size = 0.25;
        return switch (tile_type) {
            .stone => .{ .u_min = 0.0, .u_max = cell_size, .v_min = 0.0, .v_max = cell_size },
            .lava => .{ .u_min = cell_size, .u_max = cell_size * 2, .v_min = 0.0, .v_max = cell_size },
            .metal => .{ .u_min = cell_size * 2, .u_max = cell_size * 3, .v_min = 0.0, .v_max = cell_size },
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

pub const StructureTextures = struct {
    const Self = @This();
    const card_count = @typeInfo(card.CardEnum).@"enum".fields.len;

    textures: [card_count]rl.Texture2D,
    models: [card_count]rl.Model,

    pub fn init() Self {
        var self: Self = .{ .textures = undefined, .models = undefined };

        inline for (0..card_count) |i| {
            const card_enum: card.CardEnum = @enumFromInt(i);
            const card_data = card.get(card_enum);
            const name: [:0]const u8 = @ptrCast(card_data.name.ptr[0..card_data.name.len :0]);

            // Create image with text
            const img_size = 256;
            var image = rl.genImageColor(img_size, img_size, rl.Color.red);
            const font_size = 32;
            const text_width = rl.measureText(name, font_size);
            const text_x: i32 = @divTrunc(img_size - text_width, 2);
            const text_y: i32 = @divTrunc(img_size - font_size, 2);
            rl.imageDrawText(&image, name, text_x, text_y, font_size, rl.Color.white);
            rl.imageFlipVertical(&image);

            const tex = rl.loadTextureFromImage(image) catch @panic("failed to load structure texture");
            self.textures[i] = tex;
            rl.unloadImage(image);

            // Create cube model with texture
            const cube_size = render.TileRenderSettings.size;
            const mesh = rl.genMeshCube(cube_size, cube_size, cube_size);
            const model = rl.loadModelFromMesh(mesh) catch @panic("failed to create structure model");
            const materials: [*]rl.Material = model.materials orelse @panic("model has null materials");
            rl.setMaterialTexture(&materials[0], .albedo, tex);
            self.models[i] = model;
        }

        return self;
    }

    pub fn get_model(self: Self, card_type: card.CardEnum) rl.Model {
        return self.models[@intFromEnum(card_type)];
    }

    pub fn deinit(self: *Self) void {
        for (&self.models) |*model| {
            model.unload();
        }
        for (&self.textures) |*tex| {
            tex.unload();
        }
    }
};

pub const BeltTextures = struct {
    const Self = @This();

    straight_model: rl.Model,
    curve_left_model: rl.Model,
    curve_right_model: rl.Model,

    pub fn init() Self {
        return .{
            .straight_model = create_belt_model("Straight", rl.Color.blue),
            .curve_left_model = create_belt_model("Left", rl.Color.green),
            .curve_right_model = create_belt_model("Right", rl.Color.orange),
        };
    }

    fn create_belt_model(name: [:0]const u8, color: rl.Color) rl.Model {
        const img_size = 256;
        var image = rl.genImageColor(img_size, img_size, color);

        const font_size = 32;
        const text_width = rl.measureText(name, font_size);
        const text_x: i32 = @divTrunc(img_size - text_width, 2);
        const text_y: i32 = @divTrunc(img_size - font_size, 2);
        rl.imageDrawText(&image, name, text_x, text_y, font_size, rl.Color.white);
        rl.imageFlipVertical(&image);

        const tex = rl.loadTextureFromImage(image) catch @panic("failed to load belt texture");
        rl.unloadImage(image);

        const cube_size = render.TileRenderSettings.size;
        const mesh = rl.genMeshCube(cube_size, cube_size * 0.5, cube_size);
        const model = rl.loadModelFromMesh(mesh) catch @panic("failed to create belt model");
        const materials: [*]rl.Material = model.materials orelse @panic("model has null materials");
        rl.setMaterialTexture(&materials[0], .albedo, tex);

        return model;
    }

    pub fn get_model(self: Self, shape: belt.Shape) rl.Model {
        return switch (shape) {
            .straight => self.straight_model,
            .curve_left => self.curve_left_model,
            .curve_right => self.curve_right_model,
        };
    }

    pub fn deinit(self: *Self) void {
        self.straight_model.unload();
        self.curve_left_model.unload();
        self.curve_right_model.unload();
    }
};

pub const Textures = struct {
    const Self = @This();

    tile_atlas: TileAtlas,
    end_turn: rl.Texture2D,
    structures: StructureTextures,
    belts: BeltTextures,
    power_pole: rl.Model,

    pub fn init() Self {
        return .{
            .tile_atlas = TileAtlas.init(),
            .end_turn = rl.loadTexture("textures/end_turn.png") catch @panic("failed to load end_turn texture"),
            .structures = StructureTextures.init(),
            .belts = BeltTextures.init(),
            .power_pole = create_power_pole_model(),
        };
    }

    pub fn deinit(self: *Self) void {
        self.tile_atlas.deinit();
        self.end_turn.unload();
        self.structures.deinit();
        self.belts.deinit();
        self.power_pole.unload();
    }
};

fn create_power_pole_model() rl.Model {
    var image = rl.genImageColor(256, 256, rl.Color.gold);
    rl.imageDrawText(&image, "Pole", 72, 112, 28, rl.Color.black);
    rl.imageFlipVertical(&image);

    const tex = rl.loadTextureFromImage(image) catch @panic("failed to load power pole texture");
    rl.unloadImage(image);

    const mesh = rl.genMeshCylinder(render.TileRenderSettings.size * 0.12, render.TileRenderSettings.size * 0.9, 8);
    const model = rl.loadModelFromMesh(mesh) catch @panic("failed to create power pole model");
    const materials: [*]rl.Material = model.materials orelse @panic("model has null materials");
    rl.setMaterialTexture(&materials[0], .albedo, tex);
    return model;
}
