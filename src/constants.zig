const sti = @import("sti");

//Sorry Theo
pub const window_width = 1920;
pub const window_height = 1080;
pub const app_name = "CARNIFEX";

pub const DebugHooks = extern struct {
    lock_io: *const fn (buffer: [*]u8, len: usize) callconv(.c) *sti.io.Writer,
    unlock_io: *const fn () callconv(.c) void,
};
