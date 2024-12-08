pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    // const in = test_input;
    const in = input;

    var timer = std.time.Timer.start() catch unreachable;

    const part1 = try findOperators(false, alloc, in);

    std.log.info("Part 1 took: {d}ms", .{timer.read() / std.time.ns_per_ms});
    timer.reset();

    const part2 = try findOperators(true, alloc, in);

    std.log.info("Part 2 took: {d}ms", .{timer.read() / std.time.ns_per_ms});

    assert(part1 == 1298103531759);
    assert(part2 == 140575048428831);

    const stdout = std.io.getStdOut().writer();
    try std.fmt.format(stdout, "Part 1: {d}\n", .{part1});
    try std.fmt.format(stdout, "Part 2: {d}\n", .{part2});
}

const Operator = enum {
    @"+",
    @"*",
    @"||",

    pub fn apply(op: @This(), a: u64, b: u64) u64 {
        return switch (op) {
            .@"+" => a +| b,
            .@"*" => a *| b,
            .@"||" => blk: {
                // Compiler makes this more efficient :)
                var a_shift = a;
                var b_shift = b;
                while (b_shift > 0) {
                    b_shift = @divTrunc(b_shift, 10);
                    a_shift *= 10;
                }

                break :blk a_shift + b;
            },
        };
    }
};

const Node = struct {
    remaining_ops: []const Operator,
    op_idx: usize,
    value: u64,
};

fn findOperators(comptime p2: bool, alloc: Allocator, buf: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, buf, '\n');

    var sum_correct: u64 = 0;

    // Reuse the same array
    var operands: std.ArrayList(u64) = .init(alloc);
    var stack: std.ArrayList(Node) = .init(alloc);
    while (lines.next()) |line| {
        defer operands.clearRetainingCapacity();
        defer stack.clearRetainingCapacity();

        if (line.len == 0) continue;
        var nums = std.mem.splitScalar(u8, line, ' ');
        const test_str = nums.first();
        assert(test_str[test_str.len - 1] == ':');
        const test_num = try std.fmt.parseInt(u64, test_str[0 .. test_str.len - 1], 10);

        while (nums.next()) |num_str| {
            const num = try std.fmt.parseInt(u64, num_str, 10);
            try operands.append(num);
        }

        const operators: []const Operator = if (p2)
            &.{ Operator.@"*", Operator.@"+", Operator.@"||" }
        else
            &.{ Operator.@"*", Operator.@"+" };

        try stack.ensureTotalCapacity(operands.items.len);
        stack.appendAssumeCapacity(.{ .remaining_ops = operators, .op_idx = 1, .value = operands.items[0] });
        if (iter(operators, &stack, operands.items, test_num)) {
            sum_correct += test_num;
        }

        // if (rec(p2, operands.items, 0, test_num)) {
        //     sum_correct += test_num;
        // }
    }

    return sum_correct;
}

fn iter(comptime operators: []const Operator, stack: *std.ArrayList(Node), operands: []const u64, target: u64) bool {
    assert(stack.items.len > 0);

    while (stack.popOrNull()) |node| {
        if (node.op_idx == operands.len) {
            if (node.value != target) continue;

            return true;
        }

        // We did all operations, go up a layer
        if (node.remaining_ops.len == 0) continue;

        const op = node.remaining_ops[0];
        const operand = operands[node.op_idx];

        // Put the remaining operations back on the stack
        stack.appendAssumeCapacity(.{
            .remaining_ops = node.remaining_ops[1..],
            .op_idx = node.op_idx,
            .value = node.value,
        });

        const new_value = op.apply(node.value, operand);

        // std.log.debug("{d} {s} {d} = {d}", .{ node.value, @tagName(op), operand, new_value });

        if (new_value > target) continue;

        stack.appendAssumeCapacity(.{
            .remaining_ops = operators,
            .op_idx = node.op_idx + 1,
            .value = new_value,
        });
    }

    return false;
}

fn rec(comptime part2: bool, ops: []const u64, value: u64, target: u64) bool {
    if (ops.len == 0) return value == target;

    inline for (.{ Operator.@"*", Operator.@"+" }) |op| {
        const new_value = op.apply(value, ops[0]);

        if (new_value <= target and rec(part2, ops[1..], new_value, target))
            return true;
    }

    if (part2) {
        const new_value = Operator.@"||".apply(value, ops[0]);

        if (new_value <= target and rec(part2, ops[1..], new_value, target))
            return true;
    }

    return false;
}

const test_input = @embedFile("test_input");
const input = @embedFile("input");

const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
