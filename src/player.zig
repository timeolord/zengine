<<<<<<< HEAD
const sti = @import("sti.zig");
=======
const sti = @import("sti");
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
const card = @import("card.zig");

const Allocator = sti.Memory.Allocator;

pub const Player = struct {
    const Self = @This();

    energy: u32,
<<<<<<< HEAD
=======
    draw_count: u32,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
    hand: card.Hand,
    deck: card.Deck,

    pub fn init() Self {
        return .{
<<<<<<< HEAD
            .energy = 0,
=======
            .energy = 5,
            .draw_count = 5,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
            .hand = card.Hand.init(),
            .deck = card.Deck.init(),
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.deck.deinit(allocator);
    }

    pub fn draw_card(self: *Self) bool {
        const drawn = self.deck.draw() orelse return false;
        return self.hand.add(drawn);
    }

    pub fn create_starting_deck(self: *Self, allocator: Allocator) !void {
<<<<<<< HEAD
        const starting_cards = [_]card.Card{
            card.Card.forge,
            card.Card.solar_panel,
            card.Card.iron_miner,
            card.Card.belts,
=======
        const starting_cards = [_]card.CardEnum{
            .forge,
            .solar_panel,
            .iron_miner,
            .tiny_tile,
            .medium_tile,
            .big_tile,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
        };
        for (starting_cards) |c| {
            try self.deck.push(allocator, c);
        }
    }
};
