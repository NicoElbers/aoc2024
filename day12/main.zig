pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    // const in = @embedFile("test_input");
    const in = @embedFile("input");

    const map = try Map.init(alloc, in, '\n');

    const part1 = try fencePrice(alloc, map);

    assert(part1 == 1930);

    const stdout = std.io.getStdOut().writer();
    try std.fmt.format(stdout, "Part 1: {d}\n", .{part1});
}

const Node = struct { pos: Position, plant_type: u8 };

fn fencePrice(alloc: Allocator, map: Map) !u32 {
    var stack = std.ArrayList(Node).init(alloc);

    var total_fence_cost: u32 = 0;

    while (std.mem.indexOfNonePos(u8, map.buf, 0, ".\n")) |start_idx| {
        const start_pos = map.idxToCoords(start_idx).?;

        var perimeter: u32 = 0;
        var area: u32 = 0;

        var seen_set = std.AutoHashMap(Position, void).init(alloc);

        try stack.append(.{ .pos = start_pos, .plant_type = map.get(start_pos).? });
        while (stack.popOrNull()) |node| {
            if (seen_set.contains(node.pos)) continue;

            const found = map.get(node.pos) orelse {
                // Outside of the map is always a new perimeter
                perimeter += 1;
                continue;
            };

            // Since we know this is not a position we've seen in this garden yet
            // we know this is a new perimeter
            if (found != node.plant_type) {
                perimeter += 1;
                continue;
            }

            // We're inside the garden, on an unseen position

            map.set(node.pos, '.');

            area += 1;
            try seen_set.putNoClobber(node.pos, {});

            inline for (std.meta.tags(Direction)) |dir| {
                try stack.append(.{
                    .pos = dir.goInDirection(node.pos),
                    .plant_type = node.plant_type,
                });
            }
        }

        total_fence_cost += area * perimeter;
    }

    return total_fence_cost;
}

// return { perimeter, sides }
// fn calculatePerimeter(map: Map, start_pos: Position) struct { u32, u32 } {
//     assert(map.validPos(start_pos));
//
//     const plant_type = map.get(start_pos).?;
//     assert(plant_type != '.');
//
//     // Arbitrarily choose to go up first
//     var dir: Direction = .up;
//     var pos = start_pos;
// }

// .A....
// AAAAA.
// .A....
//

// fn moveAlongPerimeter(map: Map, pos: Position, dir: Direction) Position {
//     assert(map.validPos(pos));
// }

const std = @import("std");
const aoc = @import("aoc.zig");

const assert = std.debug.assert;

const Allocator = std.mem.Allocator;
const Map = aoc.WorldMap;
const Direction = aoc.Direction;
const Position = aoc.Position;
