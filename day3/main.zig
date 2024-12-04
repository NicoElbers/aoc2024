pub fn main() !void {
    const in = input;

    std.log.info("Part 1: {d}", .{try fsm(in, false)});
    std.log.info("Part 2: {d}", .{try fsm(in, true)});
}

const test_input = @embedFile("test_input");
const input = @embedFile("input");

const State = union(enum) {
    begin,
    d,
    do,
    @"do(",
    don,
    m,
    @"mul(",
    num1: struct { num1_begin: usize },
    comma: struct { num1: u64 },
    num2: struct { num1: u64, num2_begin: usize },
};

pub fn fsm(buf: []const u8, enable_inst: bool) !u64 {
    var result: u64 = 0;

    var enabled = true;
    var i: usize = 0;
    state: switch (@as(State, .begin)) {
        .begin => {
            if (i + "mul(0,0)".len >= buf.len) break :state;

            defer i += 1;
            switch (buf[i]) {
                'm' => continue :state .m,
                'd' => continue :state .d,
                else => continue :state .begin,
            }
        },
        .d => switch (buf[i]) {
            0 => break :state,
            'o' => {
                i += 1;
                continue :state .do;
            },
            'm' => {
                i += 1;
                continue :state .m;
            },
            'd' => {
                i += 1;
                continue :state .d;
            },
            else => {
                i += 1;
                continue :state .begin;
            },
        },
        .do => switch (buf[i]) {
            0 => break :state,
            '(' => {
                i += 1;
                continue :state .@"do(";
            },
            'n' => {
                i += 1;
                continue :state .don;
            },

            'm' => {
                i += 1;
                continue :state .m;
            },
            'd' => {
                i += 1;
                continue :state .d;
            },
            else => {
                i += 1;
                continue :state .begin;
            },
        },
        .@"do(" => switch (buf[i]) {
            ')' => {
                enabled = true;

                i += 1;
                continue :state .begin;
            },
            'm' => {
                i += 1;
                continue :state .m;
            },
            'd' => {
                i += 1;
                continue :state .d;
            },
            else => {
                i += 1;
                continue :state .begin;
            },
        },
        .don => {
            if (buf[i] == 0) break :state;

            const ul_buf = buf[i .. i + "'t()".len];
            for (ul_buf, "'t()") |e1, e2| {
                if (e1 != e2) {
                    // Don't move foreward, for ease
                    continue :state .begin;
                }
            }

            enabled = false;

            i += "'t()".len;
            continue :state .@"mul(";
        },
        .m => {
            if (buf[i] == 0) break :state;
            const ul_buf = buf[i .. i + "ul(".len];
            for (ul_buf, "ul(") |e1, e2| {
                if (e1 != e2) {
                    // Don't move foreward, for ease
                    continue :state .begin;
                }
            }

            i += "ul(".len;
            continue :state .@"mul(";
        },
        .@"mul(" => switch (buf[i]) {
            0 => break :state,
            '0'...'9' => {
                defer i += 1;
                continue :state State{ .num1 = .{ .num1_begin = i } };
            },
            'm' => {
                i += 1;
                continue :state .m;
            },
            'd' => {
                i += 1;
                continue :state .d;
            },
            else => {
                i += 1;
                continue :state .begin;
            },
        },
        .num1 => |s| switch (buf[i]) {
            0 => break :state,
            '0'...'9' => {
                i += 1;
                continue :state .{ .num1 = s };
            },
            ',' => {
                const num1 = try std.fmt.parseInt(u64, buf[s.num1_begin..i], 10);

                i += 1;
                continue :state .{ .comma = .{ .num1 = num1 } };
            },
            'm' => {
                i += 1;
                continue :state .m;
            },
            'd' => {
                i += 1;
                continue :state .d;
            },
            else => {
                i += 1;
                continue :state .begin;
            },
        },
        .comma => |s| switch (buf[i]) {
            0 => break :state,
            '0'...'9' => {
                defer i += 1;
                continue :state .{ .num2 = .{ .num1 = s.num1, .num2_begin = i } };
            },
            'm' => {
                i += 1;
                continue :state .m;
            },
            'd' => {
                i += 1;
                continue :state .d;
            },
            else => {
                i += 1;
                continue :state .begin;
            },
        },
        .num2 => |s| switch (buf[i]) {
            0 => break :state,
            '0'...'9' => {
                i += 1;
                continue :state .{ .num2 = s };
            },
            ')' => {
                const num2 = try std.fmt.parseInt(u64, buf[s.num2_begin..i], 10);

                if (enabled or !enable_inst) {
                    result += s.num1 * num2;
                }

                i += 1;
                continue :state .begin;
            },
            'm' => {
                i += 1;
                continue :state .m;
            },
            'd' => {
                i += 1;
                continue :state .d;
            },
            else => {
                i += 1;
                continue :state .begin;
            },
        },
    }

    return result;
}

const std = @import("std");
const assert = std.debug.assert;
