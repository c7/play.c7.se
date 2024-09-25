const std = @import("std");
const w4 = @import("w4");

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

export fn update() void {
    t += 0.025;

    for (1..14) |i| {
        const r: f32 = @floatFromInt(i);
        const x: i32 = @intFromFloat(80 + (cos(t) * (r * 4)));
        const y: i32 = @intFromFloat(80 + (sin(t + r / 3) * (r * 4)));

        w4.color(if (i % 2 == 0) 0x40 else if (i == 13) 0x31 else 0x20);
        w4.circle(x, y, @intFromFloat(r * 1.9));

        if (i == 13) {
            w4.color(3);
            w4.text("11!", x - 10, y - 4);
        }
    }
}
