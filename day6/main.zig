pub fn main() !void {
    // const in = test_input;
    const in = input;

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    var map = try WorldMap.init(alloc, in, '\n');

    const part1, const part2 = try patrolMap(alloc, &map);

    // assert(part1 == 4656);
    // assert(part2 == 1575);

    const stdout = std.io.getStdOut().writer();

    try std.fmt.format(stdout, "Part 1: {d}\n", .{part1});
    try std.fmt.format(stdout, "Part 2: {d}\n", .{part2});
}

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

    pub fn idxToCoords(self: WorldMap, idx: usize) ?struct { isize, isize } {
        if (idx >= self.buf.len) return null;
        const y: isize = @intCast(@divFloor(idx, self.width + 1));
        const x: isize = @intCast(@mod(idx, self.width + 1));

        const found_idx = self.coordsToIdx(x, y);
        assert(found_idx == idx);

        if (self.buf[found_idx] == self.boundary) return null;
        return .{ x, y };
    }

    pub fn coordsToIdx(self: WorldMap, x: isize, y: isize) usize {
        return @intCast((self.width + 1) * @as(usize, @intCast(y)) + @as(usize, @intCast(x)));
    }

    pub fn get(self: WorldMap, x: isize, y: isize) ?u8 {
        if (x < 0 or y < 0 or x >= self.width or y >= self.height)
            return null;

        const idx = self.coordsToIdx(x, y);

        const out = self.buf[idx];

        assert(out != self.boundary);

        return out;
    }

    pub fn set(self: *WorldMap, x: isize, y: isize, char: u8) void {
        const idx = self.coordsToIdx(x, y);

        self.buf[idx] = char;
    }
};

const Direction = enum {
    up,
    down,
    left,
    right,

    pub fn goInDirection(dir: Direction, x: isize, y: isize) struct { isize, isize } {
        // Origin is in top left corner
        return switch (dir) {
            .up => .{ x, y - 1 },
            .left => .{ x - 1, y },
            .down => .{ x, y + 1 },
            .right => .{ x + 1, y },
        };
    }

    pub fn goBack(dir: Direction, x: isize, y: isize) struct { isize, isize } {
        return goInDirection(switch (dir) {
            .up => .down,
            .down => .up,
            .left => .right,
            .right => .left,
        }, x, y);
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

const Position = struct { x: isize, y: isize, d: Direction };

fn patrolMap(alloc: Allocator, map: *WorldMap) !struct { usize, u32 } {
    var timer = std.time.Timer.start() catch unreachable;
    const starting_pos = std.mem.indexOfScalar(u8, map.buf, '^').?;

    var part_1: u32 = 1;

    var x: isize, var y: isize = map.idxToCoords(starting_pos).?;
    var direction: Direction = .up;

    var original_positions: std.ArrayList(Position) = .init(alloc);

    // Calculate part 1, and log all locations the guard has been
    while (map.get(x, y)) |char| {
        switch (char) {
            '#' => {
                x, y = direction.goBack(x, y);
                direction = direction.turnRight();
            },
            '.' => {
                part_1 += 1;
                try original_positions.append(.{ .x = x, .y = y, .d = direction });
                map.set(x, y, 'X');
            },
            '^', 'X' => {},
            else => unreachable,
        }
        x, y = direction.goInDirection(x, y);

        // std.debug.print("{s}\n", .{map.buf});
        // std.time.sleep(std.time.ns_per_s);
    }

    std.log.info("Part 1 took {d} us", .{timer.read() / std.time.us_per_ms});

    var part_2: u32 = 0;

    const Context = struct {
        pub fn hash(self: @This(), k: Position) u64 {
            _ = self;

            assert(k.x >= 0);
            assert(k.y >= 0);

            return @intCast(k.y * 5101 + k.x * 13 + @intFromEnum(k.d));
        }
        pub fn eql(self: @This(), k1: Position, k2: Position) bool {
            _ = self;

            return k1.x == k2.x and
                k1.y == k2.y and
                k1.d == k2.d;
        }
    };

    const Map = std.HashMap(Position, void, Context, 80);
    var obstacles_seen: Map = .init(alloc);

    outer: for (original_positions.items) |start_pos| {
        defer obstacles_seen.clearRetainingCapacity();

        const idx = map.coordsToIdx(start_pos.x, start_pos.y);
        assert(map.buf[idx] == 'X');
        map.buf[idx] = 'O';
        defer map.buf[idx] = 'X'; // Revert

        // Reset
        direction = start_pos.d;
        x = start_pos.x;
        y = start_pos.y;

        while (map.get(x, y)) |char| {
            switch (char) {
                '#', 'O' => {
                    const pos: Position = .{ .x = x, .y = y, .d = direction };

                    if (obstacles_seen.contains(pos)) {
                        part_2 += 1;
                        // std.log.info("Loop of {d}", .{seen.count()});
                        // std.debug.print("Succeeded {d}, {d}", .{ x, y });
                        continue :outer;
                    }

                    // obstacles_seen.putAssumeCapacity(pos, {});
                    try obstacles_seen.put(pos, {});

                    x, y = direction.goBack(x, y);
                    direction = direction.turnRight();
                },
                '^', 'X', '.' => {},
                else => unreachable,
            }
            x, y = direction.goInDirection(x, y);
        }

        // std.log.info("Failed after {d}", .{seen.count()});
        // std.debug.print("Failed {d}, {d}", .{ x, y });
    }

    std.log.info("Part 2 took {d} ms", .{timer.read() / std.time.ns_per_ms});

    return .{ part_1, part_2 };
}

const test_input = @embedFile("test_input");
const input = @embedFile("input");

const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
