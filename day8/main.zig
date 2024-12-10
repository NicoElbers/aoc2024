pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    // const in = test_input;
    const in = input;
    var map: WorldMap = try .init(alloc, in, '\n');

    const part1, const part2 = try uniqueAntinodes(alloc, &map);

    const stdout = std.io.getStdOut().writer();

    try std.fmt.format(stdout, "Part 1: {d}\n", .{part1});
    try std.fmt.format(stdout, "Part 2: {d}\n", .{part2});
}

const Position = struct {
    x: isize,
    y: isize,

    pub fn add(rhs: Position, lhs: Position) Position {
        return .{ .x = rhs.x + lhs.x, .y = rhs.y + lhs.y };
    }
};
const WorldMap = struct {
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

    pub fn set(self: *WorldMap, pos: Position, char: u8) void {
        const idx = self.coordsToIdx(pos) orelse return;

        self.buf[idx] = char;
    }

    pub fn validPos(self: WorldMap, pos: Position) bool {
        const x = pos.x;
        const y = pos.y;

        return x >= 0 and y >= 0 and x < self.width and y < self.height;
    }
};

fn uniqueAntinodes(alloc: Allocator, world_map: *WorldMap) !struct { u32, u32 } {
    const antenna_map_len = 26 + 26 + 10;
    var antenna_map: [antenna_map_len]std.ArrayListUnmanaged(Position) = .{std.ArrayListUnmanaged(Position){}} ** antenna_map_len;

    for (world_map.buf, 0..) |c, idx| switch (c) {
        '0'...'9' => {
            const map_idx = c - '0';
            try antenna_map[map_idx].append(alloc, world_map.idxToCoords(idx).?);
        },
        'A'...'Z' => {
            const map_idx = c - '0' - ":;<=>?@".len;
            try antenna_map[map_idx].append(alloc, world_map.idxToCoords(idx).?);
        },
        'a'...'z' => {
            const map_idx = c - '0' - ":;<=>?@".len - "[\\]^_`".len;
            try antenna_map[map_idx].append(alloc, world_map.idxToCoords(idx).?);
        },
        '.', '\n' => {},
        else => unreachable,
    };

    var antinode_set_part1 = std.AutoHashMap(Position, void).init(alloc);
    var antinode_set_part2 = std.AutoHashMap(Position, void).init(alloc);

    for (antenna_map) |list| {
        // Get all pairs
        for (list.items, 1..) |item_i, i| {
            for (list.items[i..]) |item_j| {
                const x_diff = item_j.x - item_i.x;
                const y_diff = item_j.y - item_i.y;

                const diff: Position = .{ .x = x_diff, .y = y_diff };
                const diff_neg: Position = .{ .x = -x_diff, .y = -y_diff };

                assert(std.meta.eql(item_j, item_i.add(diff)));
                assert(std.meta.eql(item_i, item_j.add(diff_neg)));

                var pos_i: Position = item_i.add(diff_neg);
                if (world_map.validPos(pos_i))
                    try antinode_set_part1.put(pos_i, {});

                pos_i = item_i;
                while (world_map.validPos(pos_i)) : (pos_i = pos_i.add(diff_neg))
                    try antinode_set_part2.put(pos_i, {});

                var pos_j: Position = item_j.add(diff);
                if (world_map.validPos(pos_j))
                    try antinode_set_part1.put(pos_j, {});

                pos_j = item_j;
                while (world_map.validPos(pos_j)) : (pos_j = pos_j.add(diff))
                    try antinode_set_part2.put(pos_j, {});
            }
        }
    }

    return .{ antinode_set_part1.count(), antinode_set_part2.count() };
}

const test_input = @embedFile("test_input");
const input = @embedFile("input");

const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
