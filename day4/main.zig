pub fn main() !void {
    // const in = test_input;
    const in = input;

    const part1, const part2 = ungaBunga(in);

    std.log.info("Part 1: {d}", .{part1});
    std.log.info("Part 2: {d}", .{part2});
}

const XmasCanvas = struct {
    buf: []const u8,
    height: usize,
    width: usize,
    boundary: u8,

    pub fn init(buf: []const u8, boundary: u8) XmasCanvas {
        const full_width = std.mem.indexOfScalar(u8, buf, '\n').?;
        const height = @divExact(buf.len, full_width);
        assert(full_width * height == buf.len);

        return XmasCanvas{
            .buf = buf,
            .width = full_width,
            .height = height - 1,
            .boundary = boundary,
        };
    }

    pub fn get(self: XmasCanvas, x: isize, y: isize) ?u8 {
        if (x < 0 or y < 0 or x >= self.width or y >= self.height)
            return null;

        const idx: usize = (self.width + 1) * @as(usize, @intCast(y)) + @as(usize, @intCast(x));

        const out = self.buf[idx];

        assert(out != self.boundary);

        return out;
    }
};

const Direction = enum {
    up,
    up_left,
    left,
    down_left,
    down,
    down_right,
    right,
    up_right,

    pub fn goInDirection(dir: Direction, x: isize, y: isize) struct { isize, isize } {
        return switch (dir) {
            .up => .{ x, y + 1 },
            .up_left => .{ x - 1, y + 1 },
            .left => .{ x - 1, y },
            .down_left => .{ x - 1, y - 1 },
            .down => .{ x, y - 1 },
            .down_right => .{ x + 1, y - 1 },
            .right => .{ x + 1, y },
            .up_right => .{ x + 1, y + 1 },
        };
    }
};

fn ungaBunga(buf: []const u8) struct { u32, u32 } {
    const canvas = XmasCanvas.init(buf, '\n');

    var part_1: u32 = 0;
    var part_2: u32 = 0;

    for (0..canvas.height) |i| {
        for (0..canvas.width) |j| {
            const y: isize = @intCast(i);
            const x: isize = @intCast(j);

            if (canvas.get(x, y) == 'X') {
                dir: for (std.meta.tags(Direction)) |direction| {
                    var this_y = y;
                    var this_x = x;

                    this_x, this_y = direction.goInDirection(this_x, this_y);

                    for ("MAS") |expected| { // Ignore X, as we already have it
                        this_x, this_y = direction.goInDirection(this_x, this_y);

                        const found = canvas.get(this_x, this_y) orelse continue :dir;

                        if (found != expected) continue :dir;
                    }

                    part_1 += 1;
                }
            }

            if (canvas.get(x, y) == 'A') blk: {
                var diag_1: [2]u8 = undefined;

                diag_1[0] = canvas.get(x - 1, y + 1) orelse break :blk;
                diag_1[1] = canvas.get(x + 1, y - 1) orelse break :blk;

                if (std.mem.indexOfScalar(u8, &diag_1, 'M') == null or
                    std.mem.indexOfScalar(u8, &diag_1, 'S') == null) break :blk;

                var diag_2: [2]u8 = undefined;

                diag_2[0] = canvas.get(x + 1, y + 1) orelse break :blk;
                diag_2[1] = canvas.get(x - 1, y - 1) orelse break :blk;

                if (std.mem.indexOfScalar(u8, &diag_2, 'M') == null or
                    std.mem.indexOfScalar(u8, &diag_2, 'S') == null) break :blk;

                part_2 += 1;
            }
        }
    }

    return .{ part_1, part_2 };
}

const test_input = @embedFile("test_input");
const input = @embedFile("input");

const std = @import("std");
const assert = std.debug.assert;
