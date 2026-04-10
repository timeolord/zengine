const sti = @import("sti.zig");
const rl = @import("raylib");

const Allocator = sti.Memory.Allocator;

pub fn append_fmt(allocator: Allocator, string: *sti.ArrayList(u8), comptime format: []const u8, args: anytype) !void {
    const s = try sti.fmt.allocPrint(allocator.to_std(), format, args);
    defer allocator.free(s);
    try string.extend_from_slice(allocator, s);
}

pub fn count_wrapped_lines(allocator: Allocator, text: []const u8, font_size: i32, max_width: i32) !usize {
    var line_buf: sti.ArrayList(u8) = .init();
    defer line_buf.deinit(allocator);

    var lines: usize = 0;
    var start: usize = 0;
    while (start < text.len) {
        var end = start;
        var last_space = start;
        while (end < text.len) {
            if (text[end] == ' ') last_space = end;
            line_buf.clear();
            try line_buf.extend_from_slice(allocator, text[start .. end + 1]);
            try line_buf.push(allocator, 0);
            const ms: [:0]const u8 = @ptrCast(line_buf.as_slice()[0 .. end - start + 1]);
            if (rl.measureText(ms, font_size) > max_width and last_space > start) {
                end = last_space;
                break;
            }
            end += 1;
        }
        lines += 1;
        start = end;
        if (start < text.len and text[start] == ' ') start += 1;
    }
    return lines;
}

pub fn draw_wrapped_text(allocator: Allocator, text: []const u8, x: i32, start_y: i32, font_size: i32, max_width: i32, line_spacing: i32, color: rl.Color) !i32 {
    var line_buf: sti.ArrayList(u8) = .init();
    defer line_buf.deinit(allocator);

    var y = start_y;
    var start: usize = 0;
    while (start < text.len) {
        var end = start;
        var last_space = start;
        while (end < text.len) {
            if (text[end] == ' ') last_space = end;
            line_buf.clear();
            try line_buf.extend_from_slice(allocator, text[start .. end + 1]);
            try line_buf.push(allocator, 0);
            const ms: [:0]const u8 = @ptrCast(line_buf.as_slice()[0 .. end - start + 1]);
            if (rl.measureText(ms, font_size) > max_width and last_space > start) {
                end = last_space;
                break;
            }
            end += 1;
        }
        line_buf.clear();
        try line_buf.extend_from_slice(allocator, text[start..end]);
        try line_buf.push(allocator, 0);
        const ds: [:0]const u8 = @ptrCast(line_buf.as_slice()[0 .. end - start]);
        rl.drawText(ds, x, y, font_size, color);
        y += font_size + line_spacing;
        start = end;
        if (start < text.len and text[start] == ' ') start += 1;
    }
    return y;
}
