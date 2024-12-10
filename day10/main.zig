pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    // const in = test_input;
    const in = input;

    const map = try WorldMap.init(alloc, in, '\n');

    const part1, const part2 = try sumTrailHeads(alloc, map);

    const stdout = std.io.getStdOut().writer();

    try std.fmt.format(stdout, "Part 1: {d}\n", .{part1});
    try std.fmt.format(stdout, "Part 2: {d}\n", .{part2});
}

const input = @embedFile("input");
const test_input = @embedFile("test_input");

const PosCount = struct { pos: Position, expected: u8 = '1' };

fn sumTrailHeads(alloc: Allocator, map: WorldMap) !struct { u32, u32 } {
    var part1: u32 = 0;
    var part2: u32 = 0;

    var stack = std.ArrayList(PosCount).init(alloc);
    var found_nines = std.AutoHashMap(Position, void).init(alloc);

    var pos_seen: usize = 0;
    while (std.mem.indexOfScalarPos(u8, map.buf, pos_seen, '0')) |idx| {
        defer stack.clearRetainingCapacity();
        defer found_nines.clearRetainingCapacity();
        pos_seen = idx + 1;

        // initial location
        try stack.append(.{ .pos = map.idxToCoords(idx).? });

        std.log.debug("Trail head at: {any}", .{stack.items[stack.items.len - 1]});

        while (stack.popOrNull()) |pc| {
            inline for (std.meta.tags(Direction)) |d| {
                const new_pos = d.goInDirection(pc.pos);

                if (map.get(new_pos)) |c| {
                    assert(c >= '0');
                    assert(c <= '9');

                    if (c == pc.expected) {
                        if (c == '9') {
                            std.log.debug("Found at {any}", .{new_pos});

                            part2 += 1;
                            try found_nines.put(new_pos, {});
                        } else {
                            try stack.append(.{ .pos = new_pos, .expected = pc.expected + 1 });
                        }
                    }
                }
            }
        }

        part1 += found_nines.count();
    }

    return .{ part1, part2 };
}

const std = @import("std");
const assert = std.debug.assert;
const aoc = @import("aoc.zig");
const Allocator = std.mem.Allocator;

const WorldMap = aoc.WorldMap;
const Direction = aoc.Direction;
const Position = aoc.Position;
