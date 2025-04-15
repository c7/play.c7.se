const std = @import("std");
const w4 = @import("w4");

const allocator = fba.allocator();
const size = 25;
const Pos = @Vector(2, i32);
const Op = enum {
    Add,
    Mul,

    pub fn str(self: Op) []const u8 {
        return switch (self) {
            .Add => " + ",
            .Mul => " * ",
        };
    }
};

var memory: [32]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&memory);
var pos: Pos = .{ 0, 0 };
var op: Op = .Mul;
var button: w4.Button = .{};
var mouse: w4.Mouse = .{};

export fn start() void {
    w4.SYSTEM_FLAGS.* = w4.SYSTEM_HIDE_GAMEPAD_OVERLAY;

    w4.palette(.{ 0xFFFFFF, 0xAE8F85, 0xD3CEBB, 0x9FA8B0 });
}

export fn update() void {
    input();
    draw();
}

fn input() void {
    button.update();

    if (button.released(0, w4.BUTTON_1)) op = .Add;
    if (button.released(0, w4.BUTTON_2)) op = .Mul;
    if (button.released(0, w4.BUTTON_LEFT) and pos[0] > 0) pos[0] -= 1;
    if (button.released(0, w4.BUTTON_RIGHT) and pos[0] < size) pos[0] += 1;
    if (button.released(0, w4.BUTTON_UP) and pos[1] > 0) pos[1] -= 1;
    if (button.released(0, w4.BUTTON_DOWN) and pos[1] < size) pos[1] += 1;

    mouse.update();

    if (mouse.pressed(w4.MOUSE_LEFT) and mouse.x > 0 and mouse.y < 155) {
        if (mouse.x < size and mouse.y < size) op = if (op == .Add) .Mul else .Add;
        if (mouse.x < 80 and mouse.x > size + 5 and pos[0] > 0) pos[0] -= 1;
        if (mouse.x > 105 and mouse.x < 155 and pos[0] < size) pos[0] += 1;
        if (mouse.y < 80 and mouse.y > size + 5 and pos[1] > 0) pos[1] -= 1;
        if (mouse.y > 105 and mouse.y < 155 and pos[1] < size) pos[1] += 1;
    }
}

fn draw() void {
    operation();
    horizontal();
    vertical();
    board();
}

fn operation() void {
    w4.color(1);
    w4.rect(5, 5, size, size);
    w4.color(3);
    w4.text(op.str(), 7, 13);
}

fn horizontal() void {
    square(1 * size, 0, pos[0] + 1, 1, color(pos[0] + 0));
    square(2 * size, 0, pos[0] + 2, 1, color(pos[0] + 1));
    square(3 * size, 0, pos[0] + 3, 1, color(pos[0] + 2));
    square(4 * size, 0, pos[0] + 4, 1, color(pos[0] + 3));
    square(5 * size, 0, pos[0] + 5, 1, color(pos[0] + 4));
}

fn vertical() void {
    square(0, 1 * size, pos[1] + 1, 1, color(pos[1] + 0));
    square(0, 2 * size, pos[1] + 2, 1, color(pos[1] + 1));
    square(0, 3 * size, pos[1] + 3, 1, color(pos[1] + 2));
    square(0, 4 * size, pos[1] + 4, 1, color(pos[1] + 3));
    square(0, 5 * size, pos[1] + 5, 1, color(pos[1] + 4));
}

fn board() void {
    for (1..6) |bx| {
        for (1..6) |by| {
            const x: i32 = @intCast(bx);
            const y: i32 = @intCast(by);
            const sx: i32 = x * size;
            const sy: i32 = y * size;
            const px: i32 = x + pos[0];
            const py: i32 = y + pos[1];
            const n: i32 = if (op == .Add) px + py else px * py;

            if (px == py) square(sx, sy, n, 1, color(pos[0] + x - 1));
            if (px > py) square(sx, sy, n, color(pos[0] + x - 1), 1);
            if (px < py) square(sx, sy, n, color(pos[1] + y - 1), 1);

            w4.color(1);
            w4.line(sx - size, 5 + sy, sx + 160, 5 + sy);
            w4.line(sx + 5, 0, sx + 5, 160);
        }
    }
}

fn square(x: i32, y: i32, n: i32, rc: u16, tc: u16) void {
    w4.color(rc);
    w4.rect(x + 5, y + 5, size, size);
    w4.color(tc);

    if (n < 10) {
        w4.text(string(n), x + 7, y + 13);
    } else if (n < 100) {
        w4.text(string(n), x + 10, y + 13);
    } else {
        w4.text(string(n), x + 6, y + 13);
    }
}

fn color(n: i32) u16 {
    return @intCast(@mod(n, 3) + 2);
}

fn string(n: i32) []const u8 {
    return if (n < 10) text(" {d}", .{n}) else text("{d} ", .{n});
}

fn text(comptime fmt: []const u8, args: anytype) []const u8 {
    const str = std.fmt.allocPrint(allocator, fmt, args) catch unreachable;
    defer allocator.free(str);

    return str;
}
