pub const Position = struct {
    x: isize,
    y: isize,

    pub fn add(rhs: Position, lhs: Position) Position {
        return .{ .x = rhs.x + lhs.x, .y = rhs.y + lhs.y };
    }
};
pub const WorldMap = struct {
    buf: []u8,
    height: usize,
    width: usize,
    boundary: u8,

    pub fn init(alloc: Allocator, buf: []const u8, boundary: u8) !WorldMap {
        const full_width = std.mem.indexOfScalar(u8, buf, '\n').?;
        const height = @divExact(buf.len, full_width);
        assert(full_width * height == buf.len);

        return WorldMap{
            .buf = try alloc.dupe(u8, buf),
            .width = full_width,
            .height = height - 1,
            .boundary = boundary,
        };
    }

    pub fn idxToCoords(self: WorldMap, idx: usize) ?Position {
        const y: isize = @intCast(@divFloor(idx, self.width + 1));
        const x: isize = @intCast(@mod(idx, self.width + 1));

        const found_idx = self.coordsToIdx(.{ .x = x, .y = y }) orelse {
            std.log.err("Invalid coords: {d}, {d}", .{ x, y });
            return null;
        };
        assert(found_idx == idx);

        if (self.buf[found_idx] == self.boundary) {
            std.log.err("Boundary", .{});
            return null;
        }
        return .{ .x = x, .y = y };
    }

    pub fn coordsToIdx(self: WorldMap, pos: Position) ?usize {
        const x = pos.x;
        const y = pos.y;

        if (!self.validPos(pos))
            return null;

        return @intCast((self.width + 1) * @as(usize, @intCast(y)) + @as(usize, @intCast(x)));
    }

    pub fn get(self: WorldMap, pos: Position) ?u8 {
        const idx = self.coordsToIdx(pos) orelse return null;

        const out = self.buf[idx];
        assert(out != self.boundary);

        return out;
    }

    pub fn set(self: WorldMap, pos: Position, char: u8) void {
        const idx = self.coordsToIdx(pos) orelse return;

        self.buf[idx] = char;
    }

    pub fn validPos(self: WorldMap, pos: Position) bool {
        const x = pos.x;
        const y = pos.y;

        return x >= 0 and y >= 0 and x < self.width and y < self.height;
    }
};

pub const Direction = enum {
    up,
    down,
    left,
    right,

    pub fn goInDirection(dir: Direction, pos: Position) Position {
        // Origin is in top left corner
        return pos.add(switch (dir) {
            .up => .{ .x = 0, .y = -1 },
            .down => .{ .x = 0, .y = 1 },
            .left => .{ .x = -1, .y = 0 },
            .right => .{ .x = 1, .y = 0 },
        });
    }

    pub fn goBack(dir: Direction, pos: Position) Position {
        return goInDirection(switch (dir) {
            .up => .down,
            .down => .up,
            .left => .right,
            .right => .left,
        }, pos);
    }

    pub fn turnRight(d: Direction) Direction {
        return switch (d) {
            .up => .right,
            .right => .down,
            .down => .left,
            .left => .up,
        };
    }
};

const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
