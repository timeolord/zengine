const std = @import("std");
const rl = @import("raylib");

pub const base_screen_height = 1080;

pub fn scale(value: u32) i32 {
    const screen_height = @max(rl.getScreenHeight(), 1);
    const ratio = @as(f32, @floatFromInt(screen_height)) / @as(f32, @floatFromInt(base_screen_height));
    return @intFromFloat(@round(@as(f32, @floatFromInt(value)) * ratio));
}

pub fn unscale(value: i32) u32 {
    const screen_height = @max(rl.getScreenHeight(), 1);
    const ratio = @as(f32, @floatFromInt(base_screen_height)) / @as(f32, @floatFromInt(screen_height));
    return @intFromFloat(@round(@as(f32, @floatFromInt(value)) * ratio));
}

pub fn print_z(buffer: []u8, comptime fmt: []const u8, args: anytype) ![:0]const u8 {
    return std.fmt.bufPrintZ(buffer, fmt, args);
}
