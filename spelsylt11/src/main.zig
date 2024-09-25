const std = @import("std");
const w4 = @import("w4");

const sfx = @import("sfx.zig");

const sin = std.math.sin;
const cos = std.math.cos;

export fn start() void {
    w4.palette(.{
        0x372a39,
        0xf5e9bf,
        0xaa644d,
        0x788374,
    });
}

var t: f32 = 0;
var d: f32 = 0.025;
var n: usize = 14;

var m: w4.Mouse = .{};
var b: w4.Button = .{};

fn input() void {
    m.update();
    b.update();

    const v: i32 = @intCast(n * 3);

    if (b.held(0, w4.BUTTON_UP)) t += 0.1;
    if (b.held(0, w4.BUTTON_DOWN)) t -= 0.1;
    if (b.pressed(0, w4.BUTTON_UP) or m.pressed(w4.MOUSE_LEFT)) sfx.up(v);
    if (b.pressed(0, w4.BUTTON_DOWN) or m.pressed(w4.MOUSE_RIGHT)) sfx.down(v);
    if (b.pressed(0, w4.BUTTON_LEFT) and n > 2) sfx.left(v);
    if (b.pressed(0, w4.BUTTON_RIGHT) and n < 14) sfx.right(v);
    if (b.pressed(0, w4.BUTTON_LEFT) and n > 2) n -|= 1;
    if (b.pressed(0, w4.BUTTON_RIGHT) and n < 14) n +|= 1;
    if (b.released(0, w4.BUTTON_UP)) d = d * -1;
    if (b.released(0, w4.BUTTON_DOWN)) d = d * -1;

    if (m.held(w4.MOUSE_LEFT)) t += 0.1;
    if (m.held(w4.MOUSE_RIGHT)) t -= 0.1;
}

export fn update() void {
    input();

    t += d;

    for (0..n) |i| {
        const r: f32 = @floatFromInt(i);
        const x: i32 = @intFromFloat(80 + (cos(t) * (r * 4)));
        const y: i32 = @intFromFloat(80 + (sin(t + r / 3) * (r * 4)));

        w4.color(if (i % 2 == 0) 0x40 else if (i == n - 1) 0x30 else 0x20);
        w4.circle(x, y, @intFromFloat(r * 1.9));

        if (i == n - 1) {
            w4.color(0x21);
            w4.circle(x, y, @intFromFloat(r * 1.5));

            if (n > 7) {
                w4.color(3);
                w4.text("11!", x - 10, y - 4);
            }
        }
    }
}
