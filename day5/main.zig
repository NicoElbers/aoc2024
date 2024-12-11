pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    // const in = test_input;
    const in = input;

    const rules, const update_list = try parse(alloc, in);

    const part1, const part2 = try fixedPrinters(alloc, rules, update_list);

    assert(part1 == 4766);
    assert(part2 == 6257);

    const stdout = std.io.getStdOut().writer();
    try std.fmt.format(stdout, "Part 1: {d}\n", .{part1});
    try std.fmt.format(stdout, "Part 2: {d}\n", .{part2});
}

fn fixedPrinters(alloc: Allocator, rules: RuleMap, update_list: UpdateList) !struct { u32, u32 } {
    var correct_middle_pages: u32 = 0;
    var fixed_middle_pages: u32 = 0;

    for (update_list.items) |update| {
        const u: std.ArrayList(Num) = update;

        var fixed: []u32 = try alloc.alloc(u32, u.items.len);

        for (u.items) |n| {
            const deps = rules.get(n) orelse {
                fixed[0] = n;
                continue;
            };

            var count: usize = 0;
            for (deps.items) |d| {
                if (std.mem.indexOfScalar(u32, u.items, d) != null)
                    count += 1;
            }

            fixed[count] = n;
        }

        if (std.mem.eql(u32, u.items, fixed)) {
            correct_middle_pages += fixed[fixed.len / 2];
        } else {
            fixed_middle_pages += fixed[fixed.len / 2];
        }
    }

    return .{ correct_middle_pages, fixed_middle_pages };
}

fn parse(alloc: Allocator, buf: []const u8) !struct { RuleMap, UpdateList } {
    var lines = std.mem.splitScalar(u8, buf, '\n');

    var rule_map = RuleMap.init(alloc);
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var nums = std.mem.splitScalar(u8, line, '|');
        const x = try std.fmt.parseInt(Num, nums.next().?, 10);
        const y = try std.fmt.parseInt(Num, nums.next().?, 10);

        const gop = try rule_map.getOrPut(y);

        if (!gop.found_existing) {
            gop.value_ptr.* = .init(alloc);
        }

        try gop.value_ptr.append(x);
    }

    var update_list = UpdateList.init(alloc);
    while (lines.next()) |line| {
        if (line.len == 0) break;

        try update_list.append(std.ArrayList(Num).init(alloc));

        const update = &update_list.items[update_list.items.len - 1];
        var nums = std.mem.splitScalar(u8, line, ',');
        while (nums.next()) |num_str| {
            const num = try std.fmt.parseInt(Num, num_str, 10);
            try update.append(num);
        }
    }

    return .{ rule_map, update_list };
}

const test_input = @embedFile("test_input");
const input = @embedFile("input");

const Num = u32;

const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const RuleMap = std.AutoHashMap(Num, std.ArrayList(Num));
const UpdateList = std.ArrayList(std.ArrayList(Num));
