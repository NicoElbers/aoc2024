pub fn main() !void {
    var lines = std.mem.splitScalar(u8, input, '\n');
    // var lines = std.mem.splitScalar(u8, test_input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    var left: std.ArrayList(u32) = try .initCapacity(alloc, 1000);
    var right: std.ArrayList(u32) = try .initCapacity(alloc, 1000);

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        try left.append(try std.fmt.parseInt(u32, line[0..5], 10));
        try right.append(try std.fmt.parseInt(u32, line[8..13], 10));
    }

    std.mem.sortUnstable(u32, left.items, {}, std.sort.asc(u32));
    std.mem.sortUnstable(u32, right.items, {}, std.sort.asc(u32));

    var difference: u32 = 0;
    for (left.items, right.items) |e_l, e_r| {
        difference += @max(e_l, e_r) - @min(e_l, e_r);
    }

    var i_l: usize = 0;
    var i_r: usize = 0;
    var similarity: u32 = 0;
    while (i_l < left.items.len) {
        const to_find = left.items[i_l];

        while (i_r < right.items.len and right.items[i_r] < to_find) : (i_r += 1) {}

        var multiplier: u32 = 0;
        while (i_r < right.items.len and right.items[i_r] == to_find) : ({
            i_r += 1;
            multiplier += 1;
        }) {}

        similarity += to_find * multiplier;

        while (i_l < left.items.len and left.items[i_l] == to_find) : (i_l += 1) {}
    }

    std.log.info("Part 1: {d}", .{difference});
    std.log.info("Part 2: {d}", .{similarity});
}

const std = @import("std");
const input = @embedFile("input");
const test_input = @embedFile("test_input");
