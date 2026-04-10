const sti = @import("sti");
const map = @import("map.zig");

pub const BeltSettings = struct {
    pub const allowed_tiles = sti.EnumBitVector(map.TileTypes).create(.{ .stone, .metal });
};

pub const Shape = enum(u2) {
    straight = 0,
    curve_left = 1,
    curve_right = 2,
};

pub const Mode = enum {
    place,
    remove,
};

pub const ToolState = struct {
    mode: ?Mode,
    rotation: map.Direction,
    hovered_tile: ?map.TilePosition,

    pub const default: ToolState = .{
        .mode = null,
        .rotation = .up,
        .hovered_tile = null,
    };
};

// checks if a belt at neighbor_pos points toward required_dir
fn does_neighbor_feed_in(structures: *const map.Structures, neighbor_pos: map.TilePosition, required_dir: map.Direction) bool {
    if (structures.get_const(neighbor_pos)) |structure| {
        if (structure.structure_type == .belt) {
            if (structure.direction) |neighbor_dir| {
                return neighbor_dir == required_dir;
            }
        }
    }
    return false;
}

// computes belt shape based on which neighbors feed into it
pub fn compute_shape(structures: *const map.Structures, pos: map.TilePosition, belt_dir: map.Direction) Shape {
    // relative directions from belt's perspective
    const left_dir = belt_dir.rotate(.left);
    const back_dir = belt_dir.mirror();
    const right_dir = belt_dir.rotate(.right);

    // neighbor positions
    const left_pos = left_dir.pos_in_dir(pos);
    const back_pos = back_dir.pos_in_dir(pos);
    const right_pos = right_dir.pos_in_dir(pos);

    // check which neighbors feed into this belt
    const left_feeds = does_neighbor_feed_in(structures, left_pos, left_dir.mirror());
    const back_feeds = does_neighbor_feed_in(structures, back_pos, back_dir.mirror());
    const right_feeds = does_neighbor_feed_in(structures, right_pos, right_dir.mirror());

    // only left feeds -> curve from left
    // only right feeds -> curve from right
    // otherwise -> straight
    if (left_feeds and !back_feeds and !right_feeds) {
        return .curve_left;
    } else if (right_feeds and !back_feeds and !left_feeds) {
        return .curve_right;
    } else {
        return .straight;
    }
}
