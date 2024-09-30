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

    pub fn iter(worm: *const Worm) Iter {
        return .{ .worm = worm, .i = worm.tail };
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

    fn draw(w: *Worm, b: *w4.Button) void {
        rect(w.x, w.y, 3);

        var it = w.iter();

        while (it.next()) |n| {
            const i = (it.i + N - 1) % N;

            rect(n.x, n.y, 3);

            if (i == w.head) {
                set(w.x, w.y, 1, switch (w.d) {
                    .up => .{ .x = CELL / 2, .y = 1 },
                    .down => .{ .x = CELL / 2, .y = CELL - 2 },
                    .left => .{ .x = 1, .y = CELL / 2 },
                    .right => .{ .x = CELL - 2, .y = CELL / 2 },
                });
            } else {
                set(n.x, n.y, 1, switch (n.d) {
                    .up => .{ .x = CELL / 2, .y = CELL - 2 },
                    .down => .{ .x = CELL / 2, .y = 1 },
                    .left => .{ .x = CELL - 2, .y = CELL / 2 },
                    .right => .{ .x = 1, .y = CELL / 2 },
                });

                const x: i32 = @intCast(n.x);
                const y: i32 = @intCast(n.y);

                w4.color(1);

                switch (n.d) {
                    .up => {
                        w4.pixel(x * CELL + 1, y * CELL + 1); // top left
                        w4.pixel((x + 1) * CELL - 2, y * CELL + 1); // top right
                    },
                    .down => {
                        w4.pixel(x * CELL + 1, (y + 1) * CELL - 2); // bottom left
                        w4.pixel((x + 1) * CELL - 2, (y + 1) * CELL - 2); // bottom right
                    },
                    .left => {
                        w4.pixel(x * CELL + 1, y * CELL + 1); // top left
                        w4.pixel(x * CELL + 1, (y + 1) * CELL - 2); // bottom left
                    },
                    .right => {
                        w4.pixel((x + 1) * CELL - 2, y * CELL + 1); // top right
                        w4.pixel((x + 1) * CELL - 2, (y + 1) * CELL - 2); // bottom right
                    },
                }

                w4.color(4);
                w4.circle(x * CELL + 4, y * CELL + 4, 2);
            }
        }

        w.score.draw(b);
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

    fn draw(s: *Score, b: *w4.Button) void {
        _ = b; // autofix
        if (!scoreEnabled) return;

        w4.color(if (@mod(time, 3) == 0) 4 else 3);
        text("\x86{d}", 2, 2, .{disk.high()});

        w4.color(if (@mod(time, 3) == 0) 3 else 4);
        text("\x85{d}", 2, 12, .{s.now});
    }
};

const Apple = struct {
    x: i16 = 0,
    y: i16 = 0,

    fn init(a: *Apple, w: *Worm) void {
        a.x = @mod(random.int(i16), SIZE);
        a.y = @mod(random.int(i16), SIZE);

        if ((a.x == SIZE and a.y == SIZE) or
            (a.x == SIZE and a.y == 0) or
            (a.x == 0 and a.y == SIZE) or
            (a.x == 0 and a.y == 0))
        {
            a.x = 1 + @mod(random.int(i16), SIZE - 2);
            a.y = 1 + @mod(random.int(i16), SIZE - 2);
        }

        var it = w.iter();

        while (it.next()) |n| {
            if (a.x == n.x and a.y == n.y) a.init(w);
        }
    }

    fn draw(a: *Apple) void {
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
var snake: Worm = .{};

var aiEnabled = true;
var scoreEnabled = true;

fn grid() void {
    w4.color(0x21);

    for (0..SIZE) |i| {
        for (0..SIZE) |j| {
            const x = (@as(i32, @intCast(i)) * CELL);
            const y = (@as(i32, @intCast(j)) * CELL);

            w4.rect(x, y, CELL, CELL);
        }
    }
}

fn palette() [4]u32 {
    return if (aiEnabled) pal.classy else pal.classy_alt;
}

export fn start() void {
    disk.increment();
    disk.load();

    const starts = disk.starts();

    for (starts) |_| {
        _ = random.intRangeAtMost(
            usize,
            starts,
            starts + starts + disk.high(),
        );
    }

    snake.init();
    apple.init(&snake);
}

fn input() void {
    if (button.pressed(0, w4.BUTTON_UP) and snake.d != .down) snake.d = .up;
    if (button.pressed(0, w4.BUTTON_DOWN) and snake.d != .up) snake.d = .down;
    if (button.pressed(0, w4.BUTTON_LEFT) and snake.d != .right) snake.d = .left;
    if (button.pressed(0, w4.BUTTON_RIGHT) and snake.d != .left) snake.d = .right;
    if (button.released(0, w4.BUTTON_1)) toggleAi();
    if (button.released(0, w4.BUTTON_2)) toggleScore();
}

fn arrowReleased() bool {
    return button.released(0, w4.BUTTON_UP) or
        button.released(0, w4.BUTTON_DOWN) or
        button.released(0, w4.BUTTON_LEFT) or
        button.released(0, w4.BUTTON_RIGHT);
}

fn toggleScore() void {
    scoreEnabled = !scoreEnabled;
}

fn toggleAi() void {
    aiEnabled = !aiEnabled;
    w4.palette(palette());
}

fn draw() void {
    grid();
    apple.draw();
    snake.draw(&button);
}

export fn update() void {
    button.update();
    input();

    time += 1;

    if (aiEnabled and !arrowReleased()) snake.ai(&apple);

    if (@mod(time, DELAY) == 0) {
        snake.detect(&apple);
        snake.move();
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
};

const Disk = struct {
    data: [2]u16 = .{ 0, 0 },

    fn update(d: *Disk, score: u16) void {
        if (d.data[1] > score) return;

        d.load();
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
        return d.data[1];
    }

    fn load(d: *Disk) void {
        _ = w4.diskr(@ptrCast(d), @sizeOf(@TypeOf(d)));
    }

    fn save(d: *Disk) void {
        if (snake.score.now > d.data[1]) {
            d.data[1] = snake.score.now;
        }

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
