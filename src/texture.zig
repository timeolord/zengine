const rl = @import("raylib");

pub const CheckerTexture = struct {
    texture: rl.Texture2D,

    pub fn init(size: i32, a: rl.Color, b: rl.Color) CheckerTexture {
        var image = rl.genImageChecked(size, size, 8, 8, a, b);
        defer rl.unloadImage(image);
        return .{
            .texture = rl.loadTextureFromImage(image) catch @panic("failed to create checker texture"),
        };
    }

    pub fn deinit(self: *CheckerTexture) void {
        self.texture.unload();
    }
};
