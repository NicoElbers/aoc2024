pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    defer std.log.info("Mem used: {d}Kb", .{arena.queryCapacity() >> 10});
    const alloc = arena.allocator();

    const in = test_input;
    var lines = std.mem.splitScalar(u8, in, '\n');

    const rules = try parseRules(&lines, alloc);

    var rule_iter = rules.iterator();
    while (rule_iter.next()) |rule| {
        std.debug.print("{d} -> ", .{rule.key_ptr.*});
        var dep_iter = rule.value_ptr.keyIterator();
        while (dep_iter.next()) |dep| {
            std.debug.print("{d}, ", .{dep.*});
        }
        std.debug.print("\n", .{});
    }

    defer std.log.info("Rules: {d}", .{rules.count()});

    const part1, const part2 = try correctMiddlePages(alloc, &lines, rules);

    std.log.info("Part1: {d}", .{part1});
    std.log.info("Part2: {d}", .{part2});
}

fn correctMiddlePages(alloc: Allocator, lines: *Spliterator, rules: Map) !struct { u32, u32 } {
    var part1: u32 = 0;
    var part2: u32 = 0;
    lines: while (lines.next()) |line| {
        if (line.len == 0) break :lines;
        defer std.log.debug("", .{});

        var order: std.ArrayList(u32) = .init(alloc);
        var excluded: std.ArrayList(u32) = .init(alloc);

        var updated_order = false;

        var nums = std.mem.splitScalar(u8, line, ',');
        while (nums.next()) |num_str| {
            const num = try std.fmt.parseInt(u32, num_str, 10);

            // Found an exluded item, discard this thingy
            if (std.mem.indexOfScalar(u32, excluded.items, num) != null) {
                std.log.debug("Excluded found {d}", .{num});
                updated_order = true;
            }

            std.log.debug("Testing {d}", .{num});

            if (rules.get(num)) |deps| {
                var dep_iter = deps.keyIterator();
                while (dep_iter.next()) |dep| {
                    std.log.debug("Excluded {d}", .{dep.*});
                    try excluded.append(dep.*);
                }
            } else {
                std.log.info("AAAAAAAAAAAAAAAAAAAA", .{});
            }

            std.log.debug("Adding {d}", .{num});
            try order.append(num);
        }

        const idx = @divFloor(order.items.len, 2);
        std.log.debug("Idx: {d}; item: {d}", .{ idx, order.items[idx] });

        if (!updated_order) {
            part1 += order.items[idx];
        }

        part2 += order.items[idx];
    }

    return .{ part1, part2 };
}

const test_input = @embedFile("test_input");
const input = @embedFile("input");

const InnerMap = std.AutoHashMapUnmanaged(u32, void);
const Map = std.AutoHashMap(u32, InnerMap);

fn parseRules(lines: *Spliterator, alloc: Allocator) !Map {
    var hm = Map.init(alloc);

    loop: while (lines.next()) |line| {
        if (line.len == 0) break :loop;

        var nums = std.mem.splitScalar(u8, line, '|');
        const x = try std.fmt.parseInt(u32, nums.first(), 10);
        const y = try std.fmt.parseInt(u32, nums.next().?, 10);

        // x has to be before y, so we map y to x to look up dependencies
        if (hm.getPtr(y)) |value| {
            try value.put(alloc, x, {});
        } else {
            var inner_map = InnerMap{};
            try inner_map.put(alloc, x, {});
            try hm.put(y, inner_map);
        }
    }

    return hm;
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const Spliterator = std.mem.SplitIterator(u8, .scalar);
