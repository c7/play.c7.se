const w4 = @import("w4");
const std = @import("std");
const sfx = @import("sfx.zig");
const pal = @import("pal.zig");

const DELAY = 4;
const SIZE = 20;
const CELL = w4.SCREEN_SIZE / SIZE;
const N = SIZE * SIZE;

const Worm = struct {
    x: i8 = 0,
    y: i8 = 0,
    d: Dir = .up,

    score: Score = .{},

    nodes: [N]Node = undefined,
    head: usize = 1,
    tail: usize = 0,

    fn crash(s: *Worm) void {
        sfx.crash(100);

        aiEnabled = true;

        s.init();
    }

    fn init(w: *Worm) void {
        w4.palette(palette());

        w.x = @mod(random.int(i8), (SIZE / 2)) + (SIZE / 4);
        w.y = @mod(random.int(i8), (SIZE / 2)) + (SIZE / 4);
        w.d = random.enumValue(Dir);

        w.nodes = .{Node.init(w.x, w.y, w.d)} ** N;
        w.head = 0;
        w.tail = 0;

        w.score.init();
    }

    fn eat(w: *Worm, a: *Apple) bool {
        const h = &w.nodes[w.head];

        return h.x == a.x and h.y == a.y;
    }

    pub fn length(w: Worm) usize {
        return ((w.head + N + 1) - w.tail) % N;
    }

    pub fn iter(w: *const Worm) Iter {
        return .{ .worm = w, .i = w.tail };
    }

    fn detect(w: *Worm, a: *Apple) void {
        { // Detect apple
            if (w.eat(a)) {
                w.score.increment();
                a.init(w);
            } else {
                w.moveTail();
            }
        }

        { // Detect crash
            if (w.x < 0 or w.x >= SIZE or w.y < 0 or w.y >= SIZE) {
                return w.crash();
            }

            var it = w.iter();

            while (it.next()) |n| {
                const i = (it.i + N - 1) % N;

                if (i != w.head and w.x == n.x and w.y == n.y) {
                    return w.crash();
                }
            }
        }
    }

    fn move(w: *Worm) void {
        switch (w.d) {
            .up => w.y -= 1,
            .down => w.y += 1,
            .left => w.x -= 1,
            .right => w.x += 1,
        }

        w.moveHead(w.d);
    }

    fn moveHead(w: *Worm, d: Dir) void {
        const h = &w.nodes[w.head];

        w.head = (w.head + 1) % N;
        w.nodes[w.head] = h.copy(d);
    }

    fn moveTail(w: *Worm) void {
        w.tail = (w.tail + 1) % N;
    }

    fn left(w: *Worm) void {
        w.d = switch (w.d) {
            .up => .left,
            .down => .right,
            .left => .down,
            .right => .up,
        };
    }

    fn right(w: *Worm) void {
        w.d = switch (w.d) {
            .up => .right,
            .down => .left,
            .left => .up,
            .right => .down,
        };
    }

    fn ai(w: *Worm, a: *Apple) void {
        const try_f: i32 = w.state(a, .forward);
        const try_l: i32 = w.state(a, .left);
        const try_r: i32 = w.state(a, .right);

        if (try_f >= try_l and try_f >= try_r) {
            return; // Continue forward
        }

        if (try_l > try_r) {
            w.left();
        } else {
            w.right();
        }
    }

    fn state(w: *Worm, a: *Apple, t: Try) i16 {
        var tx: i16 = w.x;
        var ty: i16 = w.y;

        switch (w.d) {
            .up => switch (t) {
                .forward => ty -= 1,
                .left => tx -= 1,
                .right => tx += 1,
            },
            .down => switch (t) {
                .forward => ty += 1,
                .left => tx += 1,
                .right => tx -= 1,
            },
            .left => switch (t) {
                .forward => tx -= 1,
                .left => ty += 1,
                .right => ty -= 1,
            },
            .right => switch (t) {
                .forward => tx += 1,
                .left => ty -= 1,
                .right => ty += 1,
            },
        }

        var reward: i16 = 0;

        { // Detect walls
            if (tx < 0 or tx > SIZE - 1 or ty < 0 or ty > SIZE - 1) {
                reward += -100;
            }
        }

        { // Detect apple
            if (tx == a.x and tx == a.y) {
                reward += 500;
            }
        }

        { // Move towards apple
            const dx: u16 = @abs(w.x - a.x);
            const dy: u16 = @abs(w.y - a.y);
            const tdx: u16 = @abs(tx - a.x);
            const tdy: u16 = @abs(ty - a.y);

            if (tdx < dx or tdy < dy) {
                reward += 5;
            }
        }

        { // TODO: Detect tail
            var it = w.iter();

            while (it.next()) |n| {
                const i = (it.i + N - 1) % N;

                if (i != w.head) {
                    if (tx == n.x and ty == n.y) {
                        reward += -50;
                    }

                    if (t == .forward and w.d == .up and tx == n.x and ty - 1 == n.y) reward += -10;
                    if (t == .forward and w.d == .down and tx == n.x and ty + 1 == n.y) reward += -10;
                    if (t == .forward and w.d == .left and tx - 1 == n.x and ty == n.y) reward += -10;
                    if (t == .forward and w.d == .right and tx + 1 == n.x and ty == n.y) reward += -10;

                    if (t == .left and w.d == .up and tx - 1 == n.x and ty - 1 == n.y) reward += -10;
                    if (t == .left and w.d == .down and tx + 1 == n.x and ty + 1 == n.y) reward += -10;
                    if (t == .left and w.d == .left and tx - 1 == n.x and ty + 1 == n.y) reward += -10;
                    if (t == .left and w.d == .right and tx + 1 == n.x and ty - 1 == n.y) reward += -10;

                    if (t == .right and w.d == .up and tx + 1 == n.x and ty - 1 == n.y) reward += -10;
                    if (t == .right and w.d == .down and tx - 1 == n.x and ty + 1 == n.y) reward += -10;
                    if (t == .right and w.d == .left and tx - 1 == n.x and ty - 1 == n.y) reward += -10;
                    if (t == .right and w.d == .right and tx + 1 == n.x and ty + 1 == n.y) reward += -10;
                }
            }
        }

        return reward;
    }

    fn draw(w: *Worm) void {
        rect(w.x, w.y, 3);

        var it = w.iter();

        while (it.next()) |n| {
            const i = (it.i + N - 1) % N;

            rect(n.x, n.y, 3);

            const x: i32 = @intCast(n.x);
            const y: i32 = @intCast(n.y);

            const xc = x * CELL;
            const yc = y * CELL;

            if (i == w.head) {
                set(w.x, w.y, 1, switch (w.d) {
                    .up => .{ .x = CELL / 2 - 1, .y = 1 },
                    .down => .{ .x = CELL / 2, .y = CELL - 2 },
                    .left => .{ .x = 1, .y = CELL / 2 },
                    .right => .{ .x = CELL - 2, .y = CELL / 2 - 1 },
                });

                w4.color(1);

                w4.pixel(xc + 1, yc + 1); // top left
                w4.pixel((x + 1) * CELL - 2, yc + 1); // top right
                w4.pixel(xc + 1, (y + 1) * CELL - 2); // bottom left
                w4.pixel((x + 1) * CELL - 2, (y + 1) * CELL - 2); // bottom right

                w4.color(3);

                switch (w.d) {
                    .up => {
                        w4.rect(xc + 2, yc, 1, 1);
                        w4.rect(xc + @as(i32, if (toggleFast) 4 else 3), yc - 1, 2, 2);
                    },
                    .down => {
                        w4.rect(xc + 5, yc + 7, 1, 1);
                        w4.rect(xc + @as(i32, if (toggleFast) 3 else 2), yc + 7, 2, 2);
                    },
                    .left => {
                        w4.rect(xc, yc + 5, 1, 1);
                        w4.rect(xc - 1, yc + @as(i32, if (toggleFast) 3 else 2), 2, 2);
                    },
                    .right => {
                        w4.rect(xc + 7, yc + 2, 1, 1);
                        w4.rect(xc + 7, yc + @as(i32, if (toggleFast) 4 else 3), 2, 2);
                    },
                }
            } else {
                set(n.x, n.y, 4, switch (n.d) {
                    .up => .{ .x = CELL / 2, .y = CELL - 2 },
                    .down => .{ .x = CELL / 2, .y = 1 },
                    .left => .{ .x = CELL - 2, .y = CELL / 2 },
                    .right => .{ .x = 1, .y = CELL / 2 },
                });

                w4.color(1);

                w4.pixel(xc + 1, yc + 1); // top left
                w4.pixel((x + 1) * CELL - 2, yc + 1); // top right
                w4.pixel(xc + 1, (y + 1) * CELL - 2); // bottom left
                w4.pixel((x + 1) * CELL - 2, (y + 1) * CELL - 2); // bottom right

                w4.color(3);
                switch (n.d) {
                    .up => w4.rect(xc + 3, yc + 7, 2, 2),
                    .down => w4.rect(xc + 3, yc - 1, 2, 2),
                    .left => w4.rect(xc + 7, yc + 3, 2, 2),
                    .right => w4.rect(xc - 1, yc + 3, 2, 2),
                }

                w4.color(4);
                w4.circle(xc + 4, yc + 4, 2);
            }
        }
    }
};

const Score = struct {
    now: u16 = 0,

    fn init(s: *Score) void {
        disk.update(s.now);

        s.now = 0;
    }

    fn increment(s: *Score) void {
        s.now += if (aiEnabled) 1 else 10;

        disk.update(s.now);

        sfx.score(20);
    }

    fn textWidth(n: u16) i32 {
        if (n < 10) return 10;
        if (n < 100) return 20;
        if (n < 1000) return 30;
        if (n < 10000) return 40;

        return 50;
    }

    fn draw(s: *Score) void {
        if (!scoreEnabled) return;

        const high = disk.high();

        w4.color(3);
        text("\x86{d}", 2, 2, .{high});

        w4.color(4);
        text("\x85{d}", textWidth(high) + 6, 2, .{s.now});
    }
};

const Apple = struct {
    x: i8 = 0,
    y: i8 = 0,

    fn init(a: *Apple, w: *Worm) void {
        a.x = @mod(random.int(i8), SIZE);
        a.y = @mod(random.int(i8), SIZE);

        if ((a.x == SIZE - 1 and a.y == SIZE - 1) or
            (a.x == SIZE - 1 and a.y == 0) or
            (a.x == 0 and a.y == SIZE - 1) or
            (a.x == 0 and a.y == 0))
        {
            a.x = 1 + @mod(random.int(i8), SIZE - 2);
            a.y = 1 + @mod(random.int(i8), SIZE - 2);
        }

        var it = w.iter();

        while (it.next()) |n| {
            if (a.x == n.x and a.y == n.y) a.init(w);
        }
    }

    fn draw(a: *Apple) void {
        w4.color(0x22);
        w4.circle(@as(i32, @intCast(a.x)) * CELL + 4, @as(i32, @intCast(a.y)) * CELL + 4, 5);

        rect(a.x, a.y, 4);

        const x: i32 = @intCast(a.x);
        const y: i32 = @intCast(a.y);

        w4.color(3);
        w4.pixel(x * CELL + CELL / 2, y * CELL);

        w4.pixel(x * CELL + CELL / 2, y * CELL + 1);
        w4.pixel(x * CELL + CELL / 2 + 1, y * CELL);
        w4.pixel(x * CELL + CELL / 2 + 1, y * CELL - 1);

        w4.color(1);
        w4.pixel(x * CELL + 1, y * CELL + 1);
        w4.pixel(x * CELL + 1, (y + 1) * CELL - 2);

        w4.pixel((x + 1) * CELL - 2, y * CELL + 1);
        w4.pixel((x + 1) * CELL - 2, (y + 1) * CELL - 2);
    }
};

var prng = std.Random.DefaultPrng.init(0);
const random = prng.random();

var button: w4.Button = .{};

var disk: Disk = .{};
var time: i32 = 0;

var apple: Apple = .{};
var worm: Worm = .{};

var aiEnabled = true;
var scoreEnabled = true;
var toggleFast = true;
var toggleSlow = true;

fn grid() void {
    w4.color(0x21);

    for (0..SIZE) |i| {
        for (0..SIZE) |j| {
            const x = (@as(i32, @intCast(i)) * CELL);
            const y = (@as(i32, @intCast(j)) * CELL);

            w4.rect(x, y, CELL, CELL);
        }
    }

    if (false and aiEnabled) {
        const ac = Vec{
            .x = @as(i32, apple.x) * CELL + 4,
            .y = @as(i32, apple.y) * CELL + 4,
        };

        const wc = Vec{
            .x = @as(i32, @intCast(worm.x)) * CELL + 4,
            .y = @as(i32, @intCast(worm.y)) * CELL + 4,
        };

        const p1 = wc.lerp(ac, 0.1);
        const p2 = wc.lerp(ac, 0.2);
        const p3 = wc.lerp(ac, 0.3);
        const p4 = wc.lerp(ac, 0.4);

        w4.color(if (toggleFast) 0x30 else 0x40);

        p1.circle(2);
        p2.circle(3);
        p3.circle(4);
        p4.circle(5);
    }
}

fn palette() [4]u32 {
    return if (aiEnabled) pal.classy else pal.classy_alt;
}

export fn start() void {
    disk.increment();

    const starts = disk.starts();

    for (starts) |_| {
        _ = random.intRangeAtMost(
            usize,
            starts,
            starts + starts + disk.high(),
        );
    }

    worm.init();
    apple.init(&worm);
}

fn input() void {
    var arrowPressed = false;

    if (button.pressed(0, w4.BUTTON_UP) and worm.d != .down and !arrowPressed) {
        arrowPressed = true;
        worm.d = .up;
    }

    if (button.pressed(0, w4.BUTTON_DOWN) and worm.d != .up and !arrowPressed) {
        arrowPressed = true;
        worm.d = .down;
    }

    if (button.pressed(0, w4.BUTTON_LEFT) and worm.d != .right and !arrowPressed) {
        arrowPressed = true;
        worm.d = .left;
    }

    if (button.pressed(0, w4.BUTTON_RIGHT) and worm.d != .left and !arrowPressed) {
        arrowPressed = true;
        worm.d = .right;
    }

    if (button.released(0, w4.BUTTON_1)) toggleAi();
    if (button.released(0, w4.BUTTON_2)) toggleScore();
}

fn arrowHeld() bool {
    return button.held(0, w4.BUTTON_UP) or
        button.held(0, w4.BUTTON_DOWN) or
        button.held(0, w4.BUTTON_LEFT) or
        button.held(0, w4.BUTTON_RIGHT);
}

fn toggleScore() void {
    scoreEnabled = !scoreEnabled;
}

fn toggleAi() void {
    aiEnabled = !aiEnabled;

    if (aiEnabled) sfx.aiOn(50) else sfx.aiOff(50);

    w4.palette(palette());
}

fn draw() void {
    grid();

    worm.score.draw();
    apple.draw();
    worm.draw();
}

export fn update() void {
    button.update();

    time += 1;

    if (aiEnabled and !arrowHeld()) worm.ai(&apple);

    input();

    if (@mod(time, 5) == 0) toggleFast = !toggleFast;
    if (@mod(time, 30) == 0) toggleSlow = !toggleSlow;

    if (@mod(time, DELAY) == 0) {
        worm.detect(&apple);
        if (aiEnabled and !arrowHeld()) worm.ai(&apple);
        worm.move();
    }

    draw();
}

fn rect(x: i16, y: i16, c: u16) void {
    w4.color(c);
    w4.rect(@as(i32, @intCast(x)) * CELL + 1, @as(i32, @intCast(y)) * CELL + 1, CELL - 2, CELL - 2);
}

fn set(x: i16, y: i16, c: u16, o: Vec) void {
    w4.color(c);
    w4.pixel(@as(i32, @intCast(x)) * CELL + o.x, @as(i32, @intCast(y)) * CELL + o.y);
}

fn text(comptime fmt: []const u8, x: i32, y: i32, args: anytype) void {
    var buf: [100]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, fmt, args) catch @panic("Oh noes!");
    w4.text(str, x, y);
}

pub const Dir = enum {
    up,
    down,
    left,
    right,
};

pub const Try = enum {
    forward,
    left,
    right,
};

pub const Vec = struct {
    x: i32 = 0,
    y: i32 = 0,

    fn lerp(v: Vec, o: Vec, t: f32) Vec {
        const V = @Vector(2, f32);

        const from: V = .{ @floatFromInt(v.x), @floatFromInt(v.y) };
        const to: V = .{ @floatFromInt(o.x), @floatFromInt(o.y) };

        const result = from + (to - from) * @as(V, @splat(t));

        return .{
            .x = @intFromFloat(result[0]),
            .y = @intFromFloat(result[1]),
        };
    }

    fn circle(v: Vec, r: u32) void {
        w4.circle(v.x, v.y, r);
    }

    fn rect(v: Vec, w: u32, h: u32) void {
        w4.rect(v.x, v.y, w, h);
    }

    fn add(v: Vec, o: Vec) Vec {
        return .{ .x = v.x + o.x, .y = v.y + o.y };
    }

    fn mul(v: Vec, o: Vec) Vec {
        return .{ .x = v.x * o.x, .y = v.y * o.y };
    }
};

const Disk = struct {
    data: [2]u16 = .{ 0, 0 },

    fn update(d: *Disk, score: u16) void {
        disk.data[1] = 0;
        disk.load();

        if (d.data[1] > score) return;

        d.data[1] = score;
        d.save();
    }

    fn increment(d: *Disk) void {
        d.load();
        d.data[0] += 1;
        d.save();
    }

    fn starts(d: *Disk) u16 {
        return d.data[0];
    }

    fn high(d: *Disk) u16 {
        disk.data[1] = 0;
        disk.load();

        return d.data[1];
    }

    fn load(d: *Disk) void {
        _ = w4.diskr(@ptrCast(d), @sizeOf(@TypeOf(d)));
    }

    fn save(d: *Disk) void {
        _ = w4.diskw(@ptrCast(d), @sizeOf(@TypeOf(d)));
    }
};

const Node = struct {
    x: i8,
    y: i8,
    d: Dir,

    pub fn init(x: i8, y: i8, d: Dir) Node {
        return .{ .x = x, .y = y, .d = d };
    }

    fn copy(self: Node, d: Dir) Node {
        return switch (d) {
            .up => init(self.x, self.y - 1, d),
            .down => init(self.x, self.y + 1, d),
            .left => init(self.x - 1, self.y, d),
            .right => init(self.x + 1, self.y, d),
        };
    }
};

const Iter = struct {
    worm: *const Worm,
    i: usize,

    pub fn next(self: *Iter) ?Node {
        if (self.i == (self.worm.head + 1) % N) return null;

        const node = self.worm.nodes[self.i];
        self.i = (self.i + 1) % N;

        return node;
    }

    pub fn peek(self: Iter) ?Node {
        if (self.i == (self.worm.head + 1) % N) return null;

        return self.worm.nodes[self.i];
    }
};
