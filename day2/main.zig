pub const std_options: std.Options = .{
    .log_level = .info,
};

pub fn main() !void {
    // var raports = std.mem.splitScalar(u8, test_input, '\n');
    var raports = std.mem.splitScalar(u8, input, '\n');

    var safe_rapports: u32 = 0;
    while (raports.next()) |report| {
        if (report.len == 0) continue;

        const is_safe = try fsmSafe(report);

        std.log.debug("Rapport: ({}) '{s}'", .{ is_safe, report });

        safe_rapports += @intFromBool(is_safe);
    }

    std.log.info("Safe rapports: {d}\n", .{safe_rapports});
}

const State = enum {
    /// Special case where the order might still get changed
    First,
    After,
};

const Order = enum {
    increasing,
    decreasing,

    pub fn get(last_point: u32, point: u32) Order {
        return if (last_point < point)
            .increasing
        else
            .decreasing;
    }
};

fn fsmSafe(rapport: []const u8) !bool {
    var data_points = std.mem.splitScalar(u8, rapport, ' ');

    var order: Order = undefined;
    var ignored_one = false;
    var ignored_first = false;
    var last_point = try std.fmt.parseInt(u32, data_points.first(), 10);
    state: switch (State.First) {
        .First => {
            const log = std.log.scoped(.first);

            const data_point = data_points.next() orelse return true;
            const point = try std.fmt.parseInt(u32, data_point, 10);

            if (last_point < point)
                order = .increasing
            else
                order = .decreasing;

            log.debug("last: {d}, curr {d}; order {s}", .{ last_point, point, @tagName(order) });

            if (!isSafe(last_point, point, order)) {
                log.debug("Unsafe: already_ignored {}", .{ignored_one});
                if (ignored_one) {
                    if (ignored_first) return false;

                    ignored_first = true;
                    log.debug("Ignoring first value", .{});
                    data_points.reset();
                    _ = data_points.next();
                    last_point = try std.fmt.parseInt(u32, data_points.next().?, 10);
                    continue :state .First;
                }

                log.debug("Ignoring second value", .{});
                ignored_one = true;
                continue :state .First;
            }

            last_point = point;
            log.debug("Safe", .{});
            continue :state .After;
        },
        .After => {
            const log = std.log.scoped(.second);

            const data_point = data_points.next() orelse return true;
            const point = try std.fmt.parseInt(u32, data_point, 10);

            log.debug("last: {d}, curr {d}; order {s}", .{ last_point, point, @tagName(order) });

            if (!isSafe(last_point, point, order)) {
                log.debug("Unsafe: already_ignored {}", .{ignored_one});

                if (ignored_one) {
                    if (ignored_first) return false;

                    ignored_first = true;
                    log.debug("Trying ignore first elem", .{});
                    data_points.reset();
                    _ = data_points.next();
                    last_point = try std.fmt.parseInt(u32, data_points.next().?, 10);
                    continue :state .First;
                }

                ignored_one = true;
            } else {
                log.debug("Safe", .{});
                last_point = point;
            }

            continue :state .After;
        },
    }
}

fn isSafe(last_point: u32, point: u32, order: Order) bool {
    const valid_order = switch (order) {
        .increasing => last_point < point,
        .decreasing => last_point > point,
    };

    const abs_diff = @max(point, last_point) - @min(point, last_point);
    const valid_diff = abs_diff >= 1 and abs_diff <= 3;

    return valid_order and valid_diff;
}

const std = @import("std");

const assert = std.debug.assert;

const test_input = @embedFile("test_input");
const input = @embedFile("input");
