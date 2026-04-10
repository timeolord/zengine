const sti = @import("sti");
const rl = @import("raylib");
const constants = @import("constants");

const config = @import("config");
const map = @import("map.zig");
const control = @import("control.zig");
const render = @import("render.zig");
<<<<<<< HEAD
const serialize = @import("serialize.zig");
const traits = @import("traits.zig");
const turn = @import("turn.zig");
const player = @import("player.zig");
=======
const turn = @import("turn.zig");
const player = @import("player.zig");
const energy = @import("energy.zig");

comptime {
    _ = energy;
}
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

const Allocator = sti.Memory.Allocator;

pub const GameState = struct {
    pub const serialize = .{.seed};
    permanent_allocator: Allocator,
    long_term_allocator: Allocator,
    frame_allocator_mem: *sti.Memory.ArenaAllocator,
    frame_allocator: Allocator,
    timer: sti.Timer,
    rng_mem: sti.Random.DefaultPrng,
    rng: sti.Random,
    seed: u64,

    map: map.Map,
    control_state: control.ControlState,
    render_state: render.RenderState,
    turn_state: turn.TurnState,
    player: player.Player,
};

pub fn init(perma_alloc: *const Allocator, long_term_allocator: *const Allocator, debug_hooks: constants.DebugHooks) callconv(.c) *anyopaque {
    sti.debug.load_hooks(debug_hooks);

    const gs = perma_alloc.create(
        GameState,
    ) catch |err| sti.debug.panic("could not init game with {}", .{err});
    var frame_alloc_raw = perma_alloc.create(
        sti.Memory.ArenaAllocator,
    ) catch |err| sti.debug.panic("could not init frame alloc with {}", .{err});
    frame_alloc_raw.* = sti.Memory.ArenaAllocator.init(sti.Memory.page_allocator);
    const frame_alloc = frame_alloc_raw.allocator();
    const seed = 0;
    gs.* = .{
        .permanent_allocator = perma_alloc.*,
        .long_term_allocator = long_term_allocator.*,
        .frame_allocator_mem = frame_alloc_raw,
        .frame_allocator = frame_alloc,
        .timer = sti.Timer.start() catch @panic("could not initialize timer"),
        .rng_mem = sti.Random.DefaultPrng.init(seed),
        .rng = undefined,
        .seed = seed,
        .map = undefined,
        .control_state = .default,
        .render_state = .default,
        .turn_state = turn.TurnState.init(),
        .player = player.Player.init(),
    };
    gs.*.rng = gs.rng_mem.random();
    gs.*.map = .init();

<<<<<<< HEAD
    gs.player.create_starting_deck(gs.long_term_allocator) catch |err| debug.panic("could not create starting deck: {}", .{err});

    init_debug(gs) catch |err| debug.panic("{}", .{err});
=======
    gs.player.create_starting_deck(gs.long_term_allocator) catch |err| sti.debug.panic("could not create starting deck: {}", .{err});

    init_debug(gs) catch |err| sti.debug.panic("{}", .{err});

    gs.render_state.init();
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

    gs.render_state.tile_atlas = render.TileAtlas.init();

    rl.setTargetFPS(render.RenderSettings.fps);

    return gs;
}

pub fn init_debug(gs: *GameState) !void {
    //World Gen
    gs.map.chunks.generate_chunk(
        gs.long_term_allocator,
        .{ .data = .{ 0, 0 } },
        &gs.rng,
    ) catch |err| sti.debug.panic("{}", .{err});

    //Serialization test
    {
        const file = sti.fs.cwd().createFile("test_serial", .{
            .read = true,
        }) catch |err| sti.debug.panic("{}\n", .{err});
        defer file.close();

        var wbuf: [2048]u8 = undefined;
        var w = file.writer(&wbuf);
        const writer_interface = &w.interface;
        sti.serialize.serialize(GameState, gs.*, writer_interface, .strings) catch |err| sti.debug.panic("{}\n", .{err});
        writer_interface.flush() catch |err| sti.debug.panic("{}\n", .{err});

        file.seekTo(0) catch |err| sti.debug.panic("{}\n", .{err});

        var rbuf: [2048]u8 = undefined;
        var r = file.reader(&rbuf);
        const reader_interface = &r.interface;
        var test_game: GameState = undefined;
        sti.serialize.deserialize(GameState, &test_game, reader_interface, gs.frame_allocator, .strings) catch |err| sti.debug.panic("{}\n", .{err});
        sti.debug.print("serialization test seed: {}\n", .{test_game.seed});
    }
}

pub fn update(gso: *anyopaque) callconv(.c) bool {
    const gs: *GameState = @ptrCast(@alignCast(gso));
    const rs = &gs.render_state;
    const cs = &gs.control_state;
    const tilemap = &gs.map;

    // maybe handle the false case of reset? only affects performance so thats a later thing.
    defer _ = gs.frame_allocator_mem.reset(.retain_capacity);

    const dt = gs.timer.lap();

    cs.process(
        rs,
        tilemap,
        &gs.player.hand,
<<<<<<< HEAD
=======
        &gs.player,
        &gs.turn_state,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
        gs.long_term_allocator,
        &gs.rng,
        dt,
    ) catch |err| sti.debug.panic("{}", .{err});

    gs.turn_state.process(&gs.player);

    gs.turn_state.process(&gs.player);

    render.render(
        gs.frame_allocator,
        &gs.render_state,
        &gs.control_state,
        &gs.map,
        &gs.player,
<<<<<<< HEAD
=======
        &gs.turn_state,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
        dt,
    ) catch |err| sti.debug.panic("{}", .{err});

    return !rl.windowShouldClose();
}

pub fn close(gso: *anyopaque) callconv(.c) void {
    const gs: *GameState = @ptrCast(@alignCast(gso));

    _ = gs;
}

pub fn reload(gso: *anyopaque, debug_hooks: constants.DebugHooks) callconv(.c) void {
    const gs: *GameState = @ptrCast(@alignCast(gso));

    sti.debug.load_hooks(debug_hooks);

    _ = gs;
}

comptime {
    if (!config.link_static) {
        @export(&init, .{ .name = "init" });
        @export(&update, .{ .name = "update" });
        @export(&close, .{ .name = "close" });
        @export(&reload, .{ .name = "reload" });
    }
}

pub const GameErrors = struct {
    pub fn chunk_not_found(allocator: Allocator, chunk_position: anytype) ![]u8 {
        const pos_str = try chunk_position.to_string(allocator);
        defer allocator.free(pos_str);
        return sti.format.alloc_print(allocator.to_std(), "cannot get chunk {s}", .{pos_str});
    }
    pub fn entity_not_found(allocator: Allocator, entity_id: anytype) ![]u8 {
        return sti.format.alloc_print(allocator.to_std(), "could not find entity with id: {}", .{entity_id});
    }
};
