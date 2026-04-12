const sti = @import("sti");
const rl = @import("raylib");

const format = @import("format.zig");

const Allocator = sti.Memory.Allocator;

pub const Length = u32;

pub const ScreenPosition = struct {
    x: Length,
    y: Length,
};

pub const ScreenSize = struct {
    width: Length,
    height: Length,
};

pub const Rectangle = struct {
    position: ScreenPosition,
    size: ScreenSize,
};

pub const DebugUI = struct {
    pub const default: DebugUI = .{};

    pub fn draw(_: *DebugUI, allocator: Allocator, dt: u64, camera_position: rl.Vector3, demo_position: rl.Vector3) !void {
        _ = allocator;

        var line_a: [128]u8 = undefined;
        var line_b: [128]u8 = undefined;
        var line_c: [128]u8 = undefined;

        const fps_text = try format.print_z(&line_a, "fps {d}", .{rl.getFPS()});
        const camera_text = try format.print_z(&line_b, "camera {d:.2} {d:.2} {d:.2}", .{ camera_position.x, camera_position.y, camera_position.z });
        const demo_text = try format.print_z(&line_c, "demo {d:.2} {d:.2} {d:.2} dt {d}us", .{
            demo_position.x,
            demo_position.y,
            demo_position.z,
            @divTrunc(dt, std.time.ns_per_us),
        });

        const padding = format.scale(16);
        const font_size = format.scale(22);

        rl.drawRectangle(padding - 8, padding - 8, format.scale(440), format.scale(110), rl.Color{ .r = 8, .g = 10, .b = 16, .a = 220 });
        rl.drawText(fps_text, padding, padding, font_size, rl.Color.white);
        rl.drawText(camera_text, padding, padding + format.scale(30), font_size, rl.Color{ .r = 180, .g = 208, .b = 255, .a = 255 });
        rl.drawText(demo_text, padding, padding + format.scale(60), font_size, rl.Color{ .r = 255, .g = 211, .b = 124, .a = 255 });
        rl.drawText("wasd moves the focus  middle mouse rotates  wheel zooms  f1 toggles this", padding, padding + format.scale(90), format.scale(16), rl.Color{ .r = 180, .g = 180, .b = 180, .a = 255 });
    }
};

const std = @import("std");
