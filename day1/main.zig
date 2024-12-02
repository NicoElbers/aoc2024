pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const alloc = arena.allocator();

    // const file = try std.fs.cwd().openFile("test_input", .{});
    const file = try std.fs.cwd().openFile("input", .{});

    const buf = try file.readToEndAlloc(alloc, 0xFFFFFFFF);

    const State = union(enum) {
        FirstNum: usize,
        Between,
        SecondNum: usize,
    };

    var row1: std.ArrayList(u32) = try .initCapacity(alloc, 1000);
    var row2: std.ArrayList(u32) = try .initCapacity(alloc, 1000);

    var i: usize = 0;
    state: switch (State{ .FirstNum = 0 }) {
        .FirstNum => |start| {
            if (i == buf.len) break :state;

            switch (buf[i]) {
                '0'...'9' => {
                    i += 1;
                    continue :state .{ .FirstNum = start };
                },
                ' ' => {
                    std.log.debug("Parsing '{s}'", .{buf[start..i]});

                    const num = try std.fmt.parseInt(u32, buf[start..i], 10);
                    try row1.append(num);

                    i += 1;
                    continue :state .Between;
                },
                else => @panic("Unexpected format"),
            }
        },
        .Between => switch (buf[i]) {
            '0'...'9' => {
                defer i += 1;
                continue :state .{ .SecondNum = i };
            },
            ' ' => {
                i += 1;
                continue :state .Between;
            },
            else => @panic("Unexpected format"),
        },
        .SecondNum => |start| switch (buf[i]) {
            '0'...'9' => {
                i += 1;
                continue :state .{ .SecondNum = start };
            },
            '\n' => {
                std.log.debug("Parsing '{s}'", .{buf[start..i]});
                const num = try std.fmt.parseInt(u32, buf[start..i], 10);
                try row2.append(num);

                i += 1;
                continue :state .{ .FirstNum = i };
            },
            else => @panic("Unexpected format"),
        },
    }

    const less_than = struct {
        pub fn f(_: void, lhs: u32, rhs: u32) bool {
            return lhs < rhs;
        }
    }.f;

    std.mem.sortUnstable(u32, row1.items, {}, less_than);
    std.mem.sortUnstable(u32, row2.items, {}, less_than);

    var distance: u32 = 0;
    for (row1.items, row2.items) |e1, e2| {
        std.log.debug("Pair: {d} {d}", .{ e1, e2 });

        distance += @max(e1, e2) - @min(e1, e2);
    }

    std.log.info("Distance: {d}\n", .{distance});

    i = undefined;

    var i_l: usize = 0;
    var i_r: usize = 0;
    var total: u32 = 0;
    while (i_l < row1.items.len) {
        // finding in left
        const finding = row1.items[i_l];
        while (i_l < row1.items.len and row1.items[i_l] == finding) : (i_l += 1) {}

        // finding in right
        while (i_r < row2.items.len and row2.items[i_r] < finding) : (i_r += 1) {}

        //counting
        var count: u32 = 0;
        while (i_r < row2.items.len and row2.items[i_r] == finding) : ({
            i_r += 1;
            count += 1;
        }) {}

        total += finding * count;
    }

    std.log.info("Total off: {d}", .{total});
}

const std = @import("std");
