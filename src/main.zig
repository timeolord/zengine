const sti = @import("sti");
const builtin = @import("builtin");
const rl = @import("raylib");
const config = @import("config");
const constants = @import("constants");

const game_import = @import("game.zig");

const GameStatePtrOpaque = *anyopaque;
const Allocator = sti.Memory.Allocator;
const assert = sti.assert;

const GameLib = struct {
    const MAX_PATH_LENGTH: comptime_int = 1024;
    exe_path_buf: [MAX_PATH_LENGTH]u8 = [_]u8{undefined} ** MAX_PATH_LENGTH,
    exe_path: []const u8 = undefined,
    lib_name: []const u8 = undefined,
    lib_copy_name: []const u8 = undefined,

    lib_path: []const u8 = undefined,

    loaded: bool = false,
    mtime: i128 = 0,

    lib: sti.DynLib = undefined,

    init: *const fn (*const Allocator, *const Allocator, constants.DebugHooks) callconv(.c) GameStatePtrOpaque = undefined,
    update: *const fn (GameStatePtrOpaque) callconv(.c) bool = undefined,
    close: *const fn (GameStatePtrOpaque) callconv(.c) void = undefined,
    reload: *const fn (GameStatePtrOpaque, constants.DebugHooks) callconv(.c) void = undefined,

    fn setup(game: *GameLib) !void {
        switch (builtin.target.os.tag) {
            .windows => {
                game.lib_name = "game.dll";
                game.lib_copy_name = "_LOADED_game.dll";
            },
            .linux => {
                game.lib_name = "../lib/libgame.so";
                game.lib_copy_name = "_LOADED_libgame.so";
            },
            else => {
                sti.log.err("unsupported platform {s}", .{@tagName(builtin.target.os.tag)});
                @panic("unsuported platform");
            },
        }

        game.exe_path = try sti.fs.selfExeDirPath(&game.exe_path_buf);

        game.exe_path_buf[game.exe_path.len] = sti.fs.path.sep;

        game.exe_path = game.exe_path_buf[0 .. game.exe_path.len + 1];

        @memcpy(game.exe_path_buf[game.exe_path.len .. game.exe_path.len + game.lib_copy_name.len], game.lib_copy_name);
        game.lib_path = game.exe_path_buf[0 .. game.exe_path.len + game.lib_copy_name.len];

        sti.log.debug("exe dir path: {s}, {d}", .{ game.exe_path, game.exe_path.len });
        sti.log.debug("dll path: {s}, {d}", .{ game.lib_path, game.lib_path.len });
        _ = game.check_updated();
    }

    fn load_lib(game: *GameLib) !void {
        sti.assert(!game.loaded);
        var dir = try sti.fs.openDirAbsolute(game.exe_path, .{});
        defer dir.close();
        try dir.copyFile(game.lib_name, dir, game.lib_path, .{});
        game.lib = try sti.DynLib.open(game.lib_path);

        game.init = game.lib.lookup(@TypeOf(game.init), "init") orelse return error.MissingFn;
        game.update = game.lib.lookup(@TypeOf(game.update), "update") orelse return error.MissingFn;
        game.close = game.lib.lookup(@TypeOf(game.close), "close") orelse return error.MissingFn;
        game.reload = game.lib.lookup(@TypeOf(game.reload), "reload") orelse return error.MissingFn;

        game.loaded = true;
        sti.log.debug("Loaded dll", .{});
    }

    fn unload_lib(game: *GameLib) !void {
        sti.assert(game.loaded);
        game.lib.close();
        var dir = try sti.fs.openDirAbsolute(game.exe_path, .{});
        defer dir.close();
        try dir.deleteFile(game.lib_copy_name);
        game.loaded = false;
    }

    fn check_updated(game: *GameLib) bool {
        var dir = sti.fs.openDirAbsolute(game.exe_path, .{}) catch return false;
        defer dir.close();

        var f = dir.openFile(game.lib_name, .{
            .lock = .exclusive,
            .lock_nonblocking = false,
        }) catch return false;
        const stat = f.stat() catch return false;
        const was_modified = stat.mtime > game.mtime;
        f.close();
        if (was_modified)
            game.mtime = stat.mtime;
        return was_modified;
    }
};

pub fn main() !void {
    var game: GameLib = .{};

    if (comptime !config.link_static) {
        game.setup() catch @panic("Couldn't setup game lib");
        game.load_lib() catch @panic("Couldn't load game");
    }
    var keep_running = true;

    rl.initWindow(constants.window_width, constants.window_height, constants.app_name);
    defer rl.closeWindow();
    rl.setExitKey(.null);

    const DEBUG_ALLOCATORS = comptime false;

    const debug_allocator = sti.Memory.DebugAllocator(.{ .thread_safe = false }).init;

    var bump_alloc_raw = if (DEBUG_ALLOCATORS) debug_allocator else sti.Memory.ArenaAllocator.init(sti.Memory.page_allocator);

    const bump_alloc = bump_alloc_raw.allocator();

    var long_term_alloc_raw = if (DEBUG_ALLOCATORS) debug_allocator else sti.Memory.GeneralPurposeAllocator(.{ .thread_safe = false }).init;
    const long_term_alloc = Allocator.from_std(long_term_alloc_raw.allocator());

    const dbg = constants.DebugHooks{
        .lock_io = &lock_stderr,
        .unlock_io = &unlock_stderr,
    };

    const gso: GameStatePtrOpaque = blk: {
        if (comptime config.link_static) {
            break :blk game_import.init(&bump_alloc, &long_term_alloc, dbg);
        } else {
            break :blk game.init(&bump_alloc, &long_term_alloc, dbg);
        }
    };

    while (keep_running) {
        if ((comptime !config.link_static) and game.check_updated()) {
            sti.log.debug("Dll modified, reloading...\n", .{});
            try game.unload_lib();
            try game.load_lib();
            game.reload(gso, dbg);
        }

        keep_running = if (comptime config.link_static)
            game_import.update(gso)
        else
            game.update(gso);
    }

    if (comptime config.link_static) {
        game_import.close(gso);
    } else {
        game.close(gso);
        try game.unload_lib();
    }
}

pub fn lock_stderr(buffer: [*]u8, len: usize) callconv(.c) *sti.io.Writer {
    return sti.debug.lock_stderr_writer(buffer[0..len]);
}

pub fn unlock_stderr() callconv(.c) void {
    return sti.debug.unlock_stderr_writer();
}
