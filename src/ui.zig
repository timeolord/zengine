const sti = @import("sti");
const debug = sti.debug;
const format = sti.format;

const rl = @import("raylib");

const game = @import("game.zig");
const control = @import("control.zig");
const camera = @import("camera.zig");
const map = @import("map.zig");
<<<<<<< HEAD
const format = @import("format.zig");
=======
const turn = @import("turn.zig");
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2

const Allocator = sti.Memory.Allocator;

const UISettings = struct {
    const font_size = 24;
    const color = rl.Color.white;
};

pub const ToolbarButton = enum {
    belt_place,
    belt_remove,
    energy_place,
    energy_remove,
};

pub const UIElement = union(enum) {
    card: usize,
    toolbar: ToolbarButton,

    pub fn is_card(self: UIElement, index: usize) bool {
        return switch (self) {
            .card => |idx| idx == index,
            else => false,
        };
    }
};

// all values are in base 1080p pixels, scaled automatically via format.scale
pub const Length = u32;

pub const ScreenPosition = struct {
    x: Length,
    y: Length,
};

pub const ScreenSize = struct {
    width: Length,
    height: Length,
};

pub const Margin = struct {
    left: Length,
    right: Length,
    top: Length,
    bottom: Length,

    pub const zero: Margin = .{ .left = 0, .right = 0, .top = 0, .bottom = 0 };
};

pub const Rectangle = struct {
    position: ScreenPosition,
    size: ScreenSize,
};

pub const Button = struct {
    const Self = @This();

    pub const TextContent = struct {
        text_box: TextBox,
        alignment: Alignment,
    };

    pub const Content = union(enum) {
        text: TextContent,
        texture: rl.Texture2D,
    };

    rect: Rectangle,
    margin: Margin,
    content: Content,
    normal_color: rl.Color,
    hovered_color: rl.Color,
    active_color: rl.Color,

    fn scaled_x(self: Self) i32 {
        return format.scale(self.rect.position.x);
    }
    fn scaled_y(self: Self) i32 {
        return format.scale(self.rect.position.y);
    }
    fn scaled_w(self: Self) i32 {
        return format.scale(self.rect.size.width);
    }
    fn scaled_h(self: Self) i32 {
        return format.scale(self.rect.size.height);
    }

    pub fn contains(self: Self, mouse_x: i32, mouse_y: i32) bool {
        const x = self.scaled_x();
        const y = self.scaled_y();
        return mouse_x >= x and mouse_x <= x + self.scaled_w() and
            mouse_y >= y and mouse_y <= y + self.scaled_h();
    }

    pub fn is_hovered(self: Self) bool {
        return self.contains(rl.getMouseX(), rl.getMouseY());
    }

    pub fn is_clicked(self: Self) bool {
        return self.is_hovered() and rl.isMouseButtonPressed(.left);
    }

    pub fn draw(self: Self, active: bool) void {
        const hovered = self.is_hovered();
        const color = if (active) self.active_color else if (hovered) self.hovered_color else self.normal_color;
        const x = self.scaled_x();
        const y = self.scaled_y();
        const w = self.scaled_w();
        const h = self.scaled_h();

        switch (self.content) {
            .text => |tc| {
                rl.drawRectangle(x, y, w, h, color);
                rl.drawRectangleLines(x, y, w, h, rl.Color.white);
                const text_w = tc.text_box.measure_width();
                const text_h = tc.text_box.measure_height();
                const tx: Length = switch (tc.alignment.horizontal) {
                    .left => self.rect.position.x,
                    .center => self.rect.position.x + (self.rect.size.width - text_w) / 2,
                    .right => self.rect.position.x + self.rect.size.width - text_w,
                };
                const ty: Length = switch (tc.alignment.vertical) {
                    .top => self.rect.position.y,
                    .center => self.rect.position.y + (self.rect.size.height - text_h) / 2,
                };
                var aligned = tc.text_box;
                aligned.rect.position = .{ .x = tx, .y = ty };
                aligned.rect.size = .{ .width = text_w, .height = text_h };
                aligned.justification = .left;
                aligned.draw();
            },
            .texture => |tex| {
                const tint = if (hovered) self.hovered_color else self.normal_color;
                rl.drawTextureEx(
                    tex,
                    .{ .x = @floatFromInt(x), .y = @floatFromInt(y) },
                    0,
                    @as(f32, @floatFromInt(h)) / @as(f32, @floatFromInt(tex.height)),
                    tint,
                );
            },
        }
    }
};

pub const TextJustification = enum { center, left, right };
pub const HorizontalAlignment = enum { center, left, right };
pub const VerticalAlignment = enum { top, center };

pub const Alignment = struct {
    horizontal: HorizontalAlignment,
    vertical: VerticalAlignment,
};

// text box that word wraps at runtime using raylib's font measurement.
// all dimensions are in base 1080p pixels, scaled automatically.
// panics if text overflows the box height.
pub const TextBox = struct {
    text: []const u8,
    rect: Rectangle,
    margin: Margin,
    font_size: Length,
    color: rl.Color,
    justification: TextJustification,
    line_gap: Length,

    // null terminates a slice into a stack buffer for raylib
    fn terminate(buf: *[256]u8, text: []const u8) [:0]const u8 {
        @memcpy(buf[0..text.len], text);
        buf[text.len] = 0;
        return @ptrCast(buf[0..text.len :0]);
    }

    fn measure(buf: *[256]u8, text: []const u8, fs: i32) i32 {
        return rl.measureText(terminate(buf, text), fs);
    }

    pub fn measure_width(self: TextBox) Length {
        var buf: [256]u8 = undefined;
        return format.unscale(measure(&buf, self.text, format.scale(self.font_size)));
    }

    pub fn measure_height(self: TextBox) Length {
        return self.font_size;
    }

    pub fn draw(self: TextBox) void {
        const margin_left = format.scale(self.margin.left);
        const margin_top = format.scale(self.margin.top);
        const margin_right = format.scale(self.margin.right);
        const margin_bottom = format.scale(self.margin.bottom);
        const x = format.scale(self.rect.position.x) + margin_left;
        const y = format.scale(self.rect.position.y) + margin_top;
        const fs = format.scale(self.font_size);
        const max_width = format.scale(self.rect.size.width) - margin_left - margin_right;
        const max_height = format.scale(self.rect.size.height) - margin_top - margin_bottom;
        const line_gap = format.scale(self.line_gap);
        const text = self.text;

        var buf: [256]u8 = undefined;
        var cy = y;
        var start: usize = 0;

        while (start < text.len) {
            var end = start;
            var last_space = start;
            while (end < text.len) {
                if (text[end] == ' ') last_space = end;
                if (measure(&buf, text[start .. end + 1], fs) > max_width and last_space > start) {
                    end = last_space;
                    break;
                }
                end += 1;
            }

            const line = terminate(&buf, text[start..end]);
            const line_width = rl.measureText(line, fs);

            const draw_x = switch (self.justification) {
                .left => x,
                .center => x + @divTrunc(max_width - line_width, 2),
                .right => x + max_width - line_width,
            };

            rl.drawText(line, draw_x, cy, fs, self.color);
            cy += fs + line_gap;

            start = end;
            if (start < text.len and text[start] == ' ') start += 1;
            if (start < text.len and cy - y + fs > max_height) @panic("text overflows textbox");
        }
    }
};

pub const DebugUI = struct {
    const Self = @This();
    fps: FPS,

    fn draw_current_layer(
        allocator: Allocator,
        string: *sti.ArrayList(u8),
        cs: *control.ControlState,
    ) !void {
        const layer = cs.mode;
        try format.append_fmt(allocator, string, "layer: {}\n", .{layer});
<<<<<<< HEAD
=======
    }

    fn draw_turn_phase(
        allocator: Allocator,
        string: *sti.ArrayList(u8),
        ts: *turn.TurnState,
    ) !void {
        try format.append_fmt(allocator, string, "turn: {}\nphase: {}\n", .{ ts.turn_number, ts.phase });
>>>>>>> 865ec282ff230ebd38d613f37d137f49ce7550e2
    }

    pub fn draw_target_focus(
        allocator: Allocator,
        string: *sti.ArrayList(u8),
        local_camera: *camera.Camera,
        tilemap: *map.Map,
    ) !void {
        const position = local_camera.current_position().to_tile_position();
        const pos_str = try position.to_string(allocator);
        defer allocator.free(pos_str);
        try format.append_fmt(allocator, string, "tile position: {s}\n", .{pos_str});
        const chunk_and_subchunk_position = position.to_chunk_and_subchunk_position();
        const chunk_str = try chunk_and_subchunk_position.chunk_position.to_string(allocator);
        defer allocator.free(chunk_str);
        const subchunk_str = try chunk_and_subchunk_position.subchunk_position.to_string(allocator);
        defer allocator.free(subchunk_str);
        try format.append_fmt(allocator, string, "chunk position: {s}\n", .{chunk_str});
        try format.append_fmt(allocator, string, "subchunk position: {s}\n", .{subchunk_str});
        const tile = tilemap.chunks.get_tile(position);
        if (tile) |tile_ptr| {
            try format.append_fmt(allocator, string, "tile type: {}\n", .{tile_ptr.tile_type});
        } else {
            try string.extend_from_slice(allocator, "tile type: .none\n");
        }
    }

    pub fn draw(
        self: *Self,
        allocator: Allocator,
        cs: *control.ControlState,
        local_camera: *camera.Camera,
        tilemap: *map.Map,
        ts: *turn.TurnState,
    ) !void {
        var string: sti.ArrayList(u8) = .init();
        defer string.deinit(allocator);
        try self.fps.draw(allocator, &string);
        try draw_target_focus(allocator, &string, local_camera, tilemap);
        try draw_current_layer(allocator, &string, cs);
        try draw_turn_phase(allocator, &string, ts);
        try string.push(allocator, 0);
        const c_string: [:0]u8 = @ptrCast(string.as_slice());
        rl.drawText(c_string, 0, 0, UISettings.font_size, UISettings.color);
    }

    pub const default: Self = .{ .fps = .default };
};

const FPS = struct {
    const Self = @This();
    const frames_history_length = 32;
    history: @Vector(frames_history_length, f64),
    index: usize,

    pub const default: Self = .{ .history = undefined, .index = 0 };
    pub fn draw(self: *Self, allocator: Allocator, string: *sti.ArrayList(u8)) !void {
        const frame_time = rl.getFrameTime();
        //Unsure if this is will ever happen, however the FPS counter in raylib does have this check.
        if (frame_time == 0) {
            return;
        }

        self.history[self.index] = rl.getFrameTime();
        self.index = (self.index + 1) % frames_history_length;
        const average = @reduce(.Add, self.history) / frames_history_length;
        const fps: f64 = @round(1 / average);
        try format.append_fmt(allocator, string, "fps: {d:.0}\n", .{fps});
    }
};
