const rl = @import("raylib");
const camera = @import("camera.zig");

pub const ControlState = struct {
    show_overlay: bool,
    move_speed: f32,

    pub const default: ControlState = .{
        .show_overlay = true,
        .move_speed = 4,
    };

    pub fn process(self: *ControlState, cam: *camera.Camera, dt: u64) void {
        if (rl.isKeyPressed(.f1)) {
            self.show_overlay = !self.show_overlay;
        }

        if (rl.isMouseButtonDown(.middle)) {
            const mouse_delta = rl.getMouseDelta();
            cam.rotation += mouse_delta.x / 100;
        }

        cam.zoom += rl.getMouseWheelMove();
        cam.zoom = @max(cam.zoom, 1);

        const dt_seconds = @as(f32, @floatFromInt(dt)) / @as(f32, @floatFromInt(std.time.ns_per_s));
        const speed = self.move_speed * dt_seconds;

        var next = cam.current_position();
        if (rl.isKeyDown(.w) or rl.isKeyDown(.up)) next.z -= speed;
        if (rl.isKeyDown(.s) or rl.isKeyDown(.down)) next.z += speed;
        if (rl.isKeyDown(.a) or rl.isKeyDown(.left)) next.x -= speed;
        if (rl.isKeyDown(.d) or rl.isKeyDown(.right)) next.x += speed;

        if (next.x != cam.current_position().x or next.z != cam.current_position().z) {
            cam.set_target(next);
        }
    }
};

const std = @import("std");
