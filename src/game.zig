const std = @import("std");
const sti = @import("sti");
const rl = @import("raylib");
const constants = @import("constants");
const config = @import("config");

const control = @import("control.zig");
const render = @import("render.zig");

const Allocator = sti.Memory.Allocator;

pub const GameState = struct {
    permanent_allocator: Allocator,
    long_term_allocator: Allocator,
    frame_allocator_mem: *sti.Memory.ArenaAllocator,
    frame_allocator: Allocator,
    timer: sti.Timer,
    elapsed_ns: u64,
    control_state: control.ControlState,
    render_state: render.RenderState,
};

pub fn init(perma_alloc: *const Allocator, long_term_allocator: *const Allocator, debug_hooks: constants.DebugHooks) callconv(.c) *anyopaque {
    sti.debug.load_hooks(debug_hooks);

    const state = perma_alloc.create(GameState) catch |err| sti.debug.panic("could not init engine state with {}", .{err});
    const frame_allocator_mem = perma_alloc.create(sti.Memory.ArenaAllocator) catch |err| sti.debug.panic("could not init frame allocator with {}", .{err});
    frame_allocator_mem.* = sti.Memory.ArenaAllocator.init(sti.Memory.page_allocator);

    state.* = .{
        .permanent_allocator = perma_alloc.*,
        .long_term_allocator = long_term_allocator.*,
        .frame_allocator_mem = frame_allocator_mem,
        .frame_allocator = frame_allocator_mem.allocator(),
        .timer = sti.Timer.start() catch @panic("could not initialize timer"),
        .elapsed_ns = 0,
        .control_state = .default,
        .render_state = .default,
    };

    state.render_state.init();
    rl.setTargetFPS(render.RenderSettings.fps);
    return state;
}

pub fn update(gso: *anyopaque) callconv(.c) bool {
    const state: *GameState = @ptrCast(@alignCast(gso));
    defer _ = state.frame_allocator_mem.reset(.retain_capacity);

    const dt = state.timer.lap();
    state.elapsed_ns +|= dt;

    state.control_state.process(&state.render_state.camera, dt);

    const elapsed_seconds = @as(f32, @floatFromInt(state.elapsed_ns)) / @as(f32, @floatFromInt(std.time.ns_per_s));
    state.render_state.demo_position = .{
        .x = @sin(elapsed_seconds) * 2.5,
        .y = 0.75 + @sin(elapsed_seconds * 2.0) * 0.25,
        .z = @cos(elapsed_seconds) * 2.5,
    };

    render.render(
        state.frame_allocator,
        &state.render_state,
        state.control_state.show_overlay,
        dt,
    ) catch |err| sti.debug.panic("render failed with {}", .{err});

    return !rl.windowShouldClose();
}

pub fn close(gso: *anyopaque) callconv(.c) void {
    const state: *GameState = @ptrCast(@alignCast(gso));
    state.render_state.deinit();
}

pub fn reload(gso: *anyopaque, debug_hooks: constants.DebugHooks) callconv(.c) void {
    const state: *GameState = @ptrCast(@alignCast(gso));
    sti.debug.load_hooks(debug_hooks);
    _ = state;
}

comptime {
    if (!config.link_static) {
        @export(&init, .{ .name = "init" });
        @export(&update, .{ .name = "update" });
        @export(&close, .{ .name = "close" });
        @export(&reload, .{ .name = "reload" });
    }
}
