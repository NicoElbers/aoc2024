pub fn main() !void {
    const in = @embedFile("input");
    // const in = @embedFile("test_input");

    const part1, const part2 = try allTokensToWin(in);

    const stdout = std.io.getStdOut().writer();

    try fmt.format(stdout, "Part 1: {d}\n", .{part1});
    try fmt.format(stdout, "Part 2: {d}\n", .{part2});
}

fn allTokensToWin(buf: []const u8) !struct { u64, u64 } {
    var iter = mem.splitScalar(u8, buf, '\n');

    var part1: u64 = 0;
    var part2: u64 = 0;

    while (try parseMachineElement(&iter)) |mat| {
        var mat_cpy = mat;
        if (tokensToWin(&mat_cpy)) |t|
            part1 += t;

        var mat_cpy2 = mat;
        mat_cpy2[0][2] += 10000000000000;
        mat_cpy2[1][2] += 10000000000000;

        if (tokensToWin(&mat_cpy2)) |t|
            part2 += t;
    }

    return .{ part1, part2 };
}

fn parseMachineElement(iter: *mem.SplitIterator(u8, .scalar)) !?AugmentedMatrix {
    const first_line = iter.next() orelse return null;
    assert(mem.startsWith(u8, first_line, "Button A: X+"));
    var first_iter = mem.splitScalar(u8, first_line["Button A: X+".len..], ',');
    const ax = try fmt.parseFloat(MatNum, first_iter.next().?);
    const ay = try fmt.parseFloat(MatNum, first_iter.next().?[" Y+".len..]);

    const second_line = iter.next().?;
    assert(mem.startsWith(u8, second_line, "Button B: X+"));
    var second_iter = mem.splitScalar(u8, second_line["Button B: X+".len..], ',');
    const bx = try fmt.parseFloat(MatNum, second_iter.next().?);
    const by = try fmt.parseFloat(MatNum, second_iter.next().?[" Y+".len..]);

    const third_line = iter.next().?;
    assert(mem.startsWith(u8, third_line, "Prize: X="));
    var prize_iter = mem.splitScalar(u8, third_line["Prize: X=".len..], ',');
    const px = try fmt.parseFloat(MatNum, prize_iter.next().?);
    const py = try fmt.parseFloat(MatNum, prize_iter.next().?[" Y=".len..]);

    // Ignore the next potential empty line
    _ = iter.next();

    return .{
        .{ ax, bx, px },
        .{ ay, by, py },
    };
}

fn tokensToWin(mat: *AugmentedMatrix) ?ResNum {
    // If the prize is at (0,0), no need to move
    if (isZero(mat[0][2], 1e-7) and isZero(mat[1][2], 1e-7)) return 0;

    std.log.debug("{any}", .{mat[0]});
    std.log.debug("{any}", .{mat[1]});
    std.log.debug("", .{});

    // Row reduce
    inline for (0..mat.len) |i| {
        // -1 because we don't want to remove the original row
        inline for (0..mat.len - 1) |j| {
            const j_idx = (i + 1 + j) % mat.len;

            // if mat[i][i] is zero, we will get fucky values
            if (isZero(mat[i][i], 1e-7)) return null;

            // zero out the ith element in the (i + 1 + j)th row
            const scale = mat[j_idx][i] / mat[i][i];
            mat[j_idx] -= @as(MatVec, @splat(scale)) * mat[i];
        }
    }

    // Normalize
    inline for (0..mat.len) |i| {

        // We know that every element until i should be zero
        // and if the ith element is zero, we have a zero vector
        if (isZero(mat[i][i], 1e-7))
            return null;

        const scale = 1 / mat[i][i];
        mat[i] *= @as(MatVec, @splat(scale));
    }

    std.log.debug("{any}", .{mat[0]});
    std.log.debug("{any}", .{mat[1]});
    std.log.debug("", .{});

    if (isInteger(mat[0][2], 1e-7) and isInteger(mat[1][2], 1e-7))
        return @intFromFloat(@round(mat[0][2]) * 3 + @round(mat[1][2]))
    else
        return null;
}

// 3
// 6

fn isZero(n: MatNum, tolerance: MatNum) bool {
    return -tolerance < n and n < tolerance;
}

fn isInteger(n: MatNum, tolerance: MatNum) bool {
    const rounded = @round(n);
    const difference = rounded - n;
    return isZero(difference, tolerance);
}

const MatVec = @Vector(3, MatNum);
const AugmentedMatrix = [2]MatVec;
const MatNum = f128;
const ResNum = u64;

const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const assert = std.debug.assert;
