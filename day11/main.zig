// Rules:
// - 0 => 1
// - even #digits => stones split (left digits in one, right digits in another)
// - else => multiply by 2024

const Num = u64;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const in = input;
    // const in = test_input;

    const rocks = try parseRocks(alloc, in);
    defer rocks.deinit();

    const part1 = try countRocks(alloc, rocks, 25);
    const part2 = try countRocks(alloc, rocks, 75);

    // Stay correct while optimizing
    assert(part1 == 183484);
    assert(part2 == 218817038947400);

    const stdout = std.io.getStdOut().writer();
    try std.fmt.format(stdout, "Part 1: {d} (183484)\n", .{part1});
    try std.fmt.format(stdout, "Part 2: {d} (218817038947400)\n", .{part2});
}

const Map = std.AutoHashMap(Num, Num);

fn countRocks(alloc: Allocator, rocks: std.ArrayList(Num), blinks: usize) !Num {
    var curr = Map.init(alloc);
    var next = Map.init(alloc);

    defer curr.deinit();
    defer next.deinit();

    for (rocks.items) |rock| {
        const entry = try curr.getOrPut(rock);

        if (!entry.found_existing) {
            entry.value_ptr.* = 0;
        }

        entry.value_ptr.* += 1;
    }

    for (0..blinks) |_| {
        // Upper bound for next iteration
        try next.ensureTotalCapacity(curr.count() * 2);
        defer { // Swap and clear
            const tmp: Map = curr;
            curr = next;
            next = tmp;

            next.clearRetainingCapacity();
        }

        var key_iter = curr.keyIterator();
        while (key_iter.next()) |rock_ptr| {
            const rock = rock_ptr.*;

            if (rock == 0) {
                const entry = next.getOrPutAssumeCapacity(1);

                if (!entry.found_existing) {
                    entry.value_ptr.* = 0;
                }

                entry.value_ptr.* += curr.get(0).?;

                continue;
            }

            assert(rock != 0);

            const digits = countDigits(rock);
            if (digits % 2 == 0) {
                const mult = try std.math.powi(Num, 10, @intCast(digits / 2));

                const left = @divTrunc(rock, mult);
                const right = @rem(rock, mult);

                inline for (.{ left, right }) |r| {
                    const entry = next.getOrPutAssumeCapacity(r);

                    if (!entry.found_existing) {
                        entry.value_ptr.* = 0;
                    }

                    entry.value_ptr.* += curr.get(rock).?;
                }

                continue;
            }

            assert(digits % 2 == 1);

            const entry = next.getOrPutAssumeCapacity(rock * 2024);

            if (!entry.found_existing) {
                entry.value_ptr.* = 0;
            }

            entry.value_ptr.* += curr.get(rock).?;
        }
    }

    var rock_count: Num = 0;
    var value_iter = curr.valueIterator();
    while (value_iter.next()) |v| {
        rock_count += v.*;
    }

    return rock_count;
}

fn parseRocks(alloc: Allocator, buf: []const u8) !std.ArrayList(Num) {
    var arr = std.ArrayList(Num).init(alloc);

    var iter = std.mem.splitScalar(u8, buf, ' ');
    while (iter.next()) |num_str| {
        try arr.append(try std.fmt.parseInt(Num, std.mem.trim(u8, num_str, "\n"), 10));
    }

    return arr;
}

fn countDigits(n: Num) usize {
    // Interestingly, this seemingly faster constant time operation is slower
    // than the loop. I guess either some LLVM intrisics pick up on the fact
    // I'm counting the digits or maybe the float conversions are just abysmally
    // slow. Who knows.
    // if (n == 0) return 1;
    //
    // const f: f64 = @floatFromInt(n);
    // const digits = @floor(@log10(f)) + 1;
    // return @intFromFloat(digits);

    var n_copy = n;

    var digits: usize = 0;
    while (n_copy > 0) : ({
        n_copy = @divTrunc(n_copy, 10);
        digits += 1;
    }) {}
    return digits;
}

const input = @embedFile("input");
const test_input = @embedFile("test_input");

const std = @import("std");
const assert = std.debug.assert;

const Allocator = std.mem.Allocator;
