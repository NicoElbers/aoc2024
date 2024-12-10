pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    // const in = test_input;
    const in = input;

    const fs = try parseFs(alloc, in);

    const fs_clone = blk: {
        var f = std.ArrayList(ID).init(alloc);
        try f.ensureTotalCapacity(fs.items.len);
        f.appendSliceAssumeCapacity(fs.items);
        break :blk f;
    };
    const part1 = compactBlocks(fs_clone);
    const part2 = try compactFiles(alloc, fs);

    assert(part1 == 6341711060162);
    assert(part2 == 6377400869326);

    const stdout = std.io.getStdOut().writer();

    try std.fmt.format(stdout, "Part 1: {d}\n", .{part1});
    try std.fmt.format(stdout, "Part 2: {d}\n", .{part2});
}

const ID = enum(u64) {
    invalid = std.math.maxInt(u64),
    _,
};

fn computeChecksum(fs: std.ArrayList(ID)) u64 {
    var checksum: u64 = 0;
    for (fs.items, 0..) |item, mul| {
        if (item == .invalid) continue;

        checksum += @as(u64, @intCast(mul * @intFromEnum(item)));
    }

    return checksum;
}

fn parseFs(alloc: Allocator, buf: []const u8) !std.ArrayList(ID) {
    var fs: std.ArrayList(ID) = .init(alloc);

    const total_size = blk: {
        var count: usize = 0;
        for (buf) |c| {
            if (c == '\n') break;
            count += c - '0';
        }
        break :blk count;
    };

    try fs.ensureUnusedCapacity(total_size);

    for (buf, 0..) |c, idx| {
        if (c == '\n') break;
        const len = c - '0';

        if (idx % 2 == 0) {
            // File size
            fs.appendNTimesAssumeCapacity(@enumFromInt(idx / 2), len);
        } else {
            // Empty size
            fs.appendNTimesAssumeCapacity(.invalid, len);
        }
    }

    return fs;
}

fn compactBlocks(fs: std.ArrayList(ID)) u64 {
    var start: usize = 0;
    var end: usize = fs.items.len - 1;
    while (start < end) : (end -= 1) {
        while (fs.items[end] == .invalid) : (end -= 1) {}
        while (fs.items[start] != .invalid) : (start += 1) {}

        if (start >= end) break;

        fs.items[start] = fs.items[end];
        fs.items[end] = .invalid;
    }

    return computeChecksum(fs);
}

const FilePos = struct { id: ID, start: usize, len: usize };
fn compactFiles(alloc: Allocator, fs: std.ArrayList(ID)) !u64 {
    // var timer = std.time.Timer.start() catch unreachable;

    var files = std.ArrayList(FilePos).init(alloc);
    var free_span = std.DoublyLinkedList(FilePos){};

    //std.log.info("Init: {d}ms", .{timer.read() / std.time.ns_per_ms});

    var state: enum { file, free } = .free;
    for (fs.items, 0..) |item, i| switch (state) {
        .free => switch (item) {
            .invalid => {
                free_span.last.?.data.len += 1;
                state = .free;
            },
            else => {
                try files.append(.{ .id = item, .start = i, .len = 1 });
                state = .file;
            },
        },
        .file => switch (item) {
            else => {
                var last_file = &files.items[files.items.len - 1];

                if (last_file.id == fs.items[i]) {
                    last_file.len += 1;
                } else {
                    try files.append(.{ .id = item, .start = i, .len = 1 });
                }

                state = .file;
            },
            .invalid => {
                const node = try alloc.create(std.DoublyLinkedList(FilePos).Node);
                node.data = .{ .id = .invalid, .start = i, .len = 1 };
                free_span.append(node);

                state = .free;
            },
        },
    };

    // var s: f64 = 0;
    // for (files.items) |item| {
    //     s += @floatFromInt(item.len);
    // }
    // std.log.info("avg len: {d}", .{s / @as(f64, @floatFromInt(files.items.len))});

    //std.log.info("File/free: {d}ms", .{timer.read() / std.time.ns_per_ms});

    //std.log.info("Loops to do: {d}", .{files.items.len});

    // var defrag_timer = std.time.Timer.start() catch unreachable;
    var sum: u64 = 0;

    // I don't think I'm allowed to remove elements, but try later anyway

    files: for (files.items, 1..) |_, i| {
        // defer //std.log.info("Loop: {d}ms", .{defrag_timer.read() / std.time.ns_per_ms});
        const idx = files.items.len - i;
        const item = &files.items[idx];

        var curr = free_span.first;

        while (curr) |c| {
            defer curr = c.next;

            // if (earliest_5_space == null and c.data.len >= 5)
            //     earliest_5_space = curr;

            // We don't want to place a file further back
            if (c.data.start > item.start) break;

            if (c.data.len >= item.len) {
                sum += checksumPos(c.data.start, item.len, item.id);

                item.id = .invalid;

                if (c.data.len == item.len) {
                    free_span.remove(c);
                } else {
                    c.data.len -= item.len;
                    c.data.start += item.len;
                }
                continue :files;
            }
        }
    }

    //std.log.info("Defrag: {d}ms", .{timer.read() / std.time.ns_per_ms});

    for (files.items) |item| {
        if (item.id == .invalid) continue;

        sum += checksumPos(item.start, item.len, item.id);
    }

    //std.log.info("Final files: {d}ms", .{timer.read() / std.time.ns_per_ms});

    return sum;
}

fn checksumPos(start: usize, len: usize, id: ID) u64 {
    assert(id != .invalid);
    // Make constant time later
    var sum: u64 = 0;
    for (start..start + len) |i| {
        sum += @intFromEnum(id) * i;
    }
    return sum;
}

const test_input = @embedFile("test_input");
const input = @embedFile("input");

const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
