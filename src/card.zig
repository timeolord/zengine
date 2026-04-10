<<<<<<< HEAD
const sti = @import("sti.zig");

const Allocator = sti.Memory.Allocator;

pub const CardType = enum {
    factory,
    material,
};

pub const Recipe = struct {
    inputs: []const struct { MaterialType, usize },
=======
const sti = @import("sti");
const map = @import("map.zig");

const Allocator = sti.Memory.Allocator;
const AllowedTiles = sti.EnumBitVector(map.TileTypes);

pub const ShapePos = struct {
    data: @Vector(2, u32),
};

pub const StructureShape = union(enum) {
    const Self = @This();

    filled: u32,
    pattern: PatternShape,

    pub fn size(self: Self) usize {
        return switch (self) {
            .filled => |n| n,
            .pattern => |p| p.dim,
        };
    }

    pub fn get(self: *const Self, pos: ShapePos) bool {
        return switch (self.*) {
            .filled => true,
            .pattern => |p| p.get(pos),
        };
    }
};

pub const PatternShape = struct {
    const Self = @This();
    pub const max_dim = 10;

    dim: u32,
    data: [max_dim * max_dim]bool,

    pub fn create(comptime dim: u32, comptime pattern: [dim * dim]bool) Self {
        var data: [max_dim * max_dim]bool = .{false} ** (max_dim * max_dim);
        for (0..dim) |y| {
            for (0..dim) |x| {
                data[y * max_dim + x] = pattern[y * dim + x];
            }
        }
        return .{ .dim = dim, .data = data };
    }

    pub fn get(self: Self, pos: ShapePos) bool {
        const x = pos.data[0];
        const y = pos.data[1];
        return self.data[y * max_dim + x];
    }
};

pub const CardType = union(enum) {
    factory: FactoryData,
    material,
};

pub const PowerRole = enum {
    none,
    producer,
    consumer,
};

pub const FactoryData = struct {
    structure_shape: ?StructureShape,
    allowed_tiles: AllowedTiles,
    power_role: PowerRole,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
};

pub const MaterialType = enum {
    iron,
    aluminium,
    silicon,
    titanium,
<<<<<<< HEAD
    // Metal types TBD
};

=======
};

pub const Card = struct {
    name: []const u8,
    energy_cost: u32,
    card_type: CardType,
    effect_text: []const u8,
};

pub const CardEnum = enum {
    forge,
    solar_panel,
    iron_miner,
    tiny_tile,
    medium_tile,
    big_tile,
};

pub const cards = sti.EnumVector(CardEnum, Card, undefined).create(.{
    .forge = .{
        .name = "Forge",
        .energy_cost = 1,
        .card_type = .{
            // L-shape: X .
            //          X X
            .factory = .{ .structure_shape = .{ .pattern = PatternShape.create(2, .{
                true, false,
                true, true,
            }) }, .allowed_tiles = AllowedTiles.create(.{ .stone, .metal }), .power_role = .none },
        },
        .effect_text = "Produces a random Factory card each turn.",
    },
    .solar_panel = .{
        .name = "Solar Panel",
        .energy_cost = 1,
        .card_type = .{ .factory = .{ .structure_shape = .{ .filled = 2 }, .allowed_tiles = AllowedTiles.create(.{ .stone, .metal }), .power_role = .producer } },
        .effect_text = "Produces 1 energy per turn.",
    },
    .iron_miner = .{
        .name = "Iron Miner",
        .energy_cost = 1,
        .card_type = .{ .factory = .{ .structure_shape = .{ .filled = 3 }, .allowed_tiles = AllowedTiles.create(.stone), .power_role = .none } },
        .effect_text = "Mines iron",
    },
    .tiny_tile = .{
        .name = "Tiny Tile",
        .energy_cost = 1,
        .card_type = .{
            .factory = .{ .structure_shape = .{ .filled = 1 }, .allowed_tiles = AllowedTiles.create(.{ .stone, .metal }), .power_role = .none },
        },
        .effect_text = "Places a 1x1 section of metal tile",
    },
    .medium_tile = .{
        .name = "Medium Tile",
        .energy_cost = 1,
        .card_type = .{
            .factory = .{ .structure_shape = .{ .filled = 3 }, .allowed_tiles = AllowedTiles.create(.{ .stone, .metal }), .power_role = .none },
        },
        .effect_text = "Places a 3x3 section of metal tile",
    },
    .big_tile = .{
        .name = "Big Tile",
        .energy_cost = 1,
        .card_type = .{
            .factory = .{ .structure_shape = .{ .filled = 5 }, .allowed_tiles = AllowedTiles.create(.{ .stone, .metal }), .power_role = .none },
        },
        .effect_text = "Places a 5x5 section of metal tile",
    },
});

pub fn get(c: CardEnum) Card {
    return cards.get(c);
}

pub fn is_tile_card(c: CardEnum) bool {
    return switch (c) {
        .tiny_tile, .medium_tile, .big_tile => true,
        else => false,
    };
}

pub fn get_power_role(c: CardEnum) PowerRole {
    return switch (get(c).card_type) {
        .factory => |factory| factory.power_role,
        .material => .none,
    };
}

>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
pub const Hand = struct {
    const Self = @This();
    const max_size = 10;

<<<<<<< HEAD
    cards: [max_size]?Card,
=======
    cards: [max_size]?CardEnum,
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
    count: usize,

    pub fn init() Self {
        return .{ .cards = .{null} ** max_size, .count = 0 };
    }

<<<<<<< HEAD
    pub fn add(self: *Self, card: Card) bool {
        if (self.count >= max_size) return false;
        self.cards[self.count] = card;
=======
    pub fn add(self: *Self, c: CardEnum) bool {
        if (self.count >= max_size) return false;
        self.cards[self.count] = c;
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
        self.count += 1;
        return true;
    }

<<<<<<< HEAD
    pub fn remove(self: *Self, index: usize) ?Card {
        if (index >= self.count) return null;
        const card = self.cards[index];
=======
    pub fn remove(self: *Self, index: usize) ?CardEnum {
        if (index >= self.count) return null;
        const c = self.cards[index];
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
        var i = index;
        while (i < self.count - 1) : (i += 1) {
            self.cards[i] = self.cards[i + 1];
        }
        self.cards[self.count - 1] = null;
        self.count -= 1;
<<<<<<< HEAD
        return card;
=======
        return c;
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
    }

    pub fn is_full(self: Self) bool {
        return self.count >= max_size;
    }
};

pub const Deck = struct {
    const Self = @This();

<<<<<<< HEAD
    cards: sti.ArrayList(Card),
=======
    cards: sti.ArrayList(CardEnum),
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

    pub fn init() Self {
        return .{ .cards = .init() };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.cards.deinit(allocator);
    }

<<<<<<< HEAD
    pub fn push(self: *Self, allocator: Allocator, card: Card) !void {
        try self.cards.push(allocator, card);
    }

    pub fn draw(self: *Self) ?Card {
=======
    pub fn push(self: *Self, allocator: Allocator, c: CardEnum) !void {
        try self.cards.push(allocator, c);
    }

    pub fn draw(self: *Self) ?CardEnum {
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
        return self.cards.pop();
    }

    pub fn shuffle(self: *Self, rng: *sti.Random) void {
<<<<<<< HEAD
        rng.shuffle(Card, self.cards.as_slice());
=======
        rng.shuffle(CardEnum, self.cards.as_slice());
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
    }

    pub fn len(self: Self) usize {
        return self.cards.len();
    }

    pub fn is_empty(self: Self) bool {
        return self.cards.is_empty();
    }
};
<<<<<<< HEAD

pub const Card = struct {
    const Self = @This();

    name: []const u8,
    energy_cost: u32,
    card_type: CardType,
    recipe: ?Recipe,
    effect_text: []const u8,
    flavour_text: []const u8,

    pub const forge: Card = .{
        .name = "Forge",
        .energy_cost = 1,
        .card_type = .factory,
        .recipe = .{
            .inputs = &.{
                .{ .iron, 2 },
            },
        },
        .effect_text = "Produces a random Factory card each turn.",
        .flavour_text = "hey u little piss baby",
    };

    pub const solar_panel: Card = .{
        .name = "Solar Panel",
        .energy_cost = 1,
        .card_type = .factory,
        .recipe = .{
            .inputs = &.{
                .{ .iron, 1 },
            },
        },
        .effect_text = "Produces 1 energy per turn.",
        .flavour_text = "the sunflower from plants vs. zombies",
    };

    pub const iron_miner: Card = .{
        .name = "Iron Miner",
        .energy_cost = 1,
        .card_type = .factory,
        .recipe = .{
            .inputs = &.{
                .{ .iron, 1 },
            },
        },
        .effect_text = "Mines iron",
        .flavour_text = "(Fe)",
    };

    pub const belts: Card = .{
        .name = "Belts",
        .energy_cost = 0,
        .card_type = .factory,
        .recipe = .{
            .inputs = &.{
                .{ .iron, 1 },
            },
        },
        .effect_text = "Connects two factories to each other",
        .flavour_text = "just like my dad",
    };
};
=======
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
