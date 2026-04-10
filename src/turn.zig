const player = @import("player.zig");

pub const TurnPhase = enum {
    draw,
    play,
    automation,
    end,
};

pub const TurnState = struct {
    const Self = @This();

    phase: TurnPhase,
    turn_number: u32,

    pub fn init() Self {
        return .{
            .phase = .draw,
            .turn_number = 1,
        };
    }

<<<<<<< HEAD
    const draw_count = 5;

    pub fn process(self: *Self, p: *player.Player) void {
        switch (self.phase) {
            .draw => {
                for (0..draw_count) |_| {
=======
    pub fn process(self: *Self, p: *player.Player) void {
        switch (self.phase) {
            .draw => {
                for (0..p.draw_count) |_| {
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
                    if (!p.draw_card()) break;
                }
                self.advance();
            },
            .play => {},
<<<<<<< HEAD
            .automation => {},
            .end => {},
=======
            .automation => {
                self.advance();
            },
            .end => {
                self.advance();
            },
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
        }
    }

    pub fn advance(self: *Self) void {
        self.phase = switch (self.phase) {
            .draw => .play,
            .play => .automation,
            .automation => .end,
            .end => blk: {
                self.turn_number += 1;
                break :blk .draw;
            },
        };
    }
};
