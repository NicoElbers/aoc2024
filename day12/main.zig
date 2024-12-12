pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    // const in = @embedFile("test_input");
    const in = @embedFile("input");

    const map = try Map.init(alloc, in, '\n');

    const part1, const part2 = try fencePrice(alloc, map);

    assert(part1 == 1304764);
    assert(part2 == 811148);

    const stdout = std.io.getStdOut().writer();
    try std.fmt.format(stdout, "Part 1: {d} (1304764)\n", .{part1});
    try std.fmt.format(stdout, "Part 2: {d} (811148)\n", .{part2});
}

const Node = struct { pos: Position, plant_type: u8 };

fn fencePrice(alloc: Allocator, map: Map) !struct { u32, u32 } {
    var stack = std.ArrayList(Node).init(alloc);

    var total_fence_cost: u32 = 0;
    var discount_fence_cost: u32 = 0;

    while (std.mem.indexOfNonePos(u8, map.buf, 0, ".\n")) |start_idx| {
        const start_pos = map.idxToCoords(start_idx).?;

        var perimeter: u32 = 0;
        var area: u32 = 0;
        var corners: u32 = 0;

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

            corners += countCorners(map, node.pos, node.plant_type);

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
        discount_fence_cost += area * corners;
    }

    return .{ total_fence_cost, discount_fence_cost };
}

// Got a hint for this one, I stopped having fun
fn countCorners(map: Map, pos: Position, plant_type: u8) u32 {
    assert(map.validPos(pos));
    assert(map.getOrig(pos).? == plant_type);

    const n = eqlPlant(plant_type, map.getOrig(.{ .x = pos.x, .y = pos.y - 1 }));
    const s = eqlPlant(plant_type, map.getOrig(.{ .x = pos.x, .y = pos.y + 1 }));

    const w = eqlPlant(plant_type, map.getOrig(.{ .x = pos.x - 1, .y = pos.y }));
    const e = eqlPlant(plant_type, map.getOrig(.{ .x = pos.x + 1, .y = pos.y }));

    const nw = eqlPlant(plant_type, map.getOrig(.{ .x = pos.x - 1, .y = pos.y - 1 }));
    const ne = eqlPlant(plant_type, map.getOrig(.{ .x = pos.x + 1, .y = pos.y - 1 }));

    const sw = eqlPlant(plant_type, map.getOrig(.{ .x = pos.x - 1, .y = pos.y + 1 }));
    const se = eqlPlant(plant_type, map.getOrig(.{ .x = pos.x + 1, .y = pos.y + 1 }));

    var count: u8 = 0;

    // OX
    // XX
    if (n and e and !ne) count += 1;
    if (n and w and !nw) count += 1;
    if (s and e and !se) count += 1;
    if (s and w and !sw) count += 1;

    // X
    if (!n and !e) count += 1;
    if (!n and !w) count += 1;
    if (!s and !e) count += 1;
    if (!s and !w) count += 1;

    return count;
}

fn eqlPlant(expected: u8, other: ?u8) bool {
    return if (other) |o| o == expected else false;
}

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
