const sti = @import("sti");
const rl = @import("raylib");

const camera = @import("camera.zig");
const ui = @import("ui.zig");

const Allocator = sti.Memory.Allocator;

pub const RenderSettings = struct {
    pub const fps = 144;
};

pub const TileRenderSettings = struct {
    pub const size: f32 = 1.0;
};

pub const RenderState = struct {
    camera: camera.Camera,
    debug_ui: ui.DebugUI,
    demo_position: rl.Vector3,

    pub const default: RenderState = .{
        .camera = .default,
        .debug_ui = .default,
        .demo_position = .{ .x = 0, .y = 1, .z = 0 },
    };

    pub fn init(_: *RenderState) void {}

    pub fn deinit(_: *RenderState) void {}
};

pub fn render(allocator: Allocator, state: *RenderState, show_overlay: bool, dt: u64) !void {
    state.camera.process(dt);

    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color{ .r = 18, .g = 24, .b = 33, .a = 255 });

    rl.beginMode3D(state.camera.to_rl_camera());
    defer rl.endMode3D();

    rl.drawGrid(20, TileRenderSettings.size);
    draw_axes();
    rl.drawCubeV(state.demo_position, .{ .x = 1.2, .y = 1.2, .z = 1.2 }, rl.Color{ .r = 221, .g = 93, .b = 71, .a = 255 });
    rl.drawCubeWiresV(state.demo_position, .{ .x = 1.2, .y = 1.2, .z = 1.2 }, rl.Color.white);

    if (show_overlay) {
        try state.debug_ui.draw(allocator, dt, state.camera.current_position(), state.demo_position);
    }
}

fn draw_axes() void {
    rl.drawLine3D(.{ .x = 0, .y = 0, .z = 0 }, .{ .x = 3, .y = 0, .z = 0 }, rl.Color.red);
    rl.drawLine3D(.{ .x = 0, .y = 0, .z = 0 }, .{ .x = 0, .y = 3, .z = 0 }, rl.Color.green);
    rl.drawLine3D(.{ .x = 0, .y = 0, .z = 0 }, .{ .x = 0, .y = 0, .z = 3 }, rl.Color.blue);
}
