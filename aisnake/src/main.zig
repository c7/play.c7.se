const w4 = @import("w4");
const std = @import("std");

const sfx = @import("sfx.zig");

const delay = 6;
const size = 20;

const cell = w4.SCREEN_SIZE / size;

const N = size * size;

var prng = std.Random.DefaultPrng.init(0);
const random = prng.random();

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

const Score = struct {
    now: i32 = 0,
    old: i32 = 0,

    fn init(s: *Score) void {
        if (s.old < s.now) s.old = s.now;

        s.now = 0;
    }

    fn increment(s: *Score) void {
        s.now += 1;

        sfx.score(20);
    }

    fn draw(s: *Score, b: *w4.Button) void {
        if (!b.held(0, w4.BUTTON_1)) return;

        w4.color(3);
        text("Now {d}", 3, 3, .{s.now});

        w4.color(4);
        text("Old {d}", 3, 13, .{s.old});
    }
};

const Node = struct {
    x: i32,
    y: i32,
    d: Dir,

    pub fn init(x: i32, y: i32, dir: Dir) Node {
        return .{ .x = x, .y = y, .d = dir };
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
    snake: *const Snake,
    i: usize,

    pub fn next(self: *Iter) ?Node {
        if (self.i == (self.snake.head + 1) % N) return null;

        const node = self.snake.nodes[self.i];
        self.i = (self.i + 1) % N;

        return node;
    }

    pub fn peek(self: Iter) ?Node {
        if (self.i == (self.snake.head + 1) % N) return null;

        return self.snake.nodes[self.i];
    }
};

const Snake = struct {
    x: i32 = 0,
    y: i32 = 0,
    d: Dir = .up,

    score: Score = .{},

    nodes: [N]Node = undefined,
    head: usize = 0,
    tail: usize = 0,
    eaten: bool = false,

    fn crash(s: *Snake) void {
        sfx.crash(100);

        s.init();
    }

    fn init(s: *Snake) void {
        s.x = @mod(random.int(i32), (size / 2)) + (size / 4);
        s.y = @mod(random.int(i32), (size / 2)) + (size / 4);
        s.d = random.enumValue(Dir);

        s.nodes = .{Node.init(s.x, s.y, s.d)} ** N;
        s.score.init();
    }

    fn eat(s: *Snake, a: *Apple) bool {
        const h = &s.nodes[s.head];
        s.eaten = h.x == a.x and h.y == a.y;

        return s.eaten;
    }

    pub fn length(s: Snake) usize {
        return ((s.head + N + 1) - s.tail) % N;
    }

    pub fn iter(self: *const Snake) Iter {
        return .{ .snake = self, .i = self.tail };
    }

    fn update(s: *Snake, a: *Apple) void {
        s.detect(a);
        s.move();
    }

    fn moveTail(s: *Snake) void {
        s.tail = (s.tail + 1) % N;
    }

    fn detect(s: *Snake, a: *Apple) void {
        { // Detect apple
            if (s.eat(a)) {
                s.score.increment();
                a.init(s);
            } else {
                s.moveTail();
            }
        }

        { // Detect crash
            if (s.x < 0 or s.x >= size or s.y < 0 or s.y >= size) {
                return s.crash();
            }

            var it = s.iter();

            while (it.next()) |n| {
                const i = (it.i + N - 1) % N;

                if (i != s.head and s.x == n.x and s.y == n.y) {
                    return s.crash();
                }
            }
        }
    }

    fn move(s: *Snake) void {
        switch (s.d) {
            .up => s.y -= 1,
            .down => s.y += 1,
            .left => s.x -= 1,
            .right => s.x += 1,
        }

        s.moveHead(s.d);
    }

    fn moveHead(self: *Snake, dir: Dir) void {
        const h = &self.nodes[self.head];

        self.head = (self.head + 1) % N;
        self.nodes[self.head] = h.copy(dir);
    }

    fn left(s: *Snake) void {
        s.d = switch (s.d) {
            .up => .left,
            .down => .right,
            .left => .down,
            .right => .up,
        };
    }

    fn right(s: *Snake) void {
        s.d = switch (s.d) {
            .up => .right,
            .down => .left,
            .left => .up,
            .right => .down,
        };
    }

    fn grow(s: *Snake) void {
        s.score.now += 1;
    }

    fn ai(s: *Snake, a: *Apple) void {
        const try_f: i32 = s.state(a, .forward);
        const try_l: i32 = s.state(a, .left);
        const try_r: i32 = s.state(a, .right);

        if (try_f >= try_l and try_f >= try_r) {
            return; // Continue forward
        }

        if (try_l > try_r) {
            s.left();
        } else {
            s.right();
        }
    }

    fn state(s: *Snake, a: *Apple, t: Try) i32 {
        var tx: i32 = s.x;
        var ty: i32 = s.y;

        switch (s.d) {
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

        var reward: i32 = 0;

        { // Detect walls
            if (tx < 0 or tx > size - 1 or ty < 0 or ty > size - 1) {
                reward += -100;
            }
        }

        { // Detect apple
            if (tx == a.x and tx == a.y) {
                reward += 500;
            }
        }

        { // Move towards apple
            const dx: u32 = @abs(s.x - a.x);
            const dy: u32 = @abs(s.y - a.y);
            const tdx: u32 = @abs(tx - a.x);
            const tdy: u32 = @abs(ty - a.y);

            if (tdx < dx or tdy < dy) {
                reward += 1;
            }
        }

        { // TODO: Detect tail
            var it = s.iter();

            while (it.next()) |n| {
                const i = (it.i + N - 1) % N;

                if (i != s.head) {
                    if (tx == n.x and ty == n.y) {
                        reward += -500;
                    }
                }
            }
        }

        return reward;
    }

    fn draw(s: *Snake, b: *w4.Button) void {
        s.score.draw(b);

        rect(s.x, s.y, 3);

        var it = s.iter();

        while (it.next()) |n| {
            const i = (it.i + N - 1) % N;

            rect(n.x, n.y, 3);

            if (i == s.head) {
                set(s.x, s.y, 1, switch (s.d) {
                    .up => .{ .x = cell / 2, .y = 1 },
                    .down => .{ .x = cell / 2, .y = cell - 2 },
                    .left => .{ .x = 1, .y = cell / 2 },
                    .right => .{ .x = cell - 2, .y = cell / 2 },
                });
            }
        }
    }
};

const Apple = struct {
    x: i32 = 0,
    y: i32 = 0,

    fn init(a: *Apple, s: *Snake) void {
        a.x = @mod(random.int(i32), size);
        a.y = @mod(random.int(i32), size);

        var it = s.iter();

        while (it.next()) |n| {
            if (a.x == n.x and a.y == n.y) a.init(s);
        }
    }

    fn draw(a: *Apple) void {
        rect(a.x, a.y, 4);

        w4.color(3);
        w4.pixel(a.x * cell + cell / 2, a.y * cell);

        w4.color(1);
        w4.pixel(a.x * cell + 1, a.y * cell + 1);
        w4.pixel(a.x * cell + 1, (a.y + 1) * cell - 2);

        w4.pixel((a.x + 1) * cell - 2, a.y * cell + 1);
        w4.pixel((a.x + 1) * cell - 2, (a.y + 1) * cell - 2);
    }
};

const Disk = struct {
    starts: usize,

    fn increment(d: *Disk) usize {
        _ = d.load();
        d.starts += 1;
        _ = d.save();
        return d.starts;
    }

    fn load(d: *Disk) u32 {
        return w4.diskr(@ptrCast(d), @sizeOf(@TypeOf(d)));
    }

    fn save(d: *Disk) u32 {
        return w4.diskw(@ptrCast(d), @sizeOf(@TypeOf(d)));
    }
};

const Game = struct {
    button: w4.Button = .{},

    disk: Disk = .{ .starts = 0 },

    time: i32 = 0,

    apple: Apple = .{},
    snake: Snake = .{ .x = 10, .y = 10, .d = .up },

    fn init(g: *Game) void {
        w4.palette(.{ 0x111111, 0x141414, 0x00FF00, 0xFF0000 });

        _ = g.disk.increment();

        for (g.disk.starts) |_| {
            _ = random.intRangeAtMost(usize, g.disk.starts, g.disk.starts + g.disk.starts);
        }

        g.snake.init();
        g.apple.init(&g.snake);
    }

    fn update(g: *Game) void {
        g.button.update();

        if (g.button.pressed(0, w4.BUTTON_UP)) g.snake.d = .up;
        if (g.button.pressed(0, w4.BUTTON_DOWN)) g.snake.d = .down;
        if (g.button.pressed(0, w4.BUTTON_LEFT)) g.snake.d = .left;
        if (g.button.pressed(0, w4.BUTTON_RIGHT)) g.snake.d = .right;

        g.time += 1;

        const tick = @mod(g.time, delay) == 0;

        if (tick) {
            g.snake.update(&g.apple);

            if (!g.button.held(0, w4.BUTTON_2)) g.snake.ai(&g.apple);
        }
    }

    fn draw(g: *Game) void {
        g.grid();
        g.apple.draw();
        g.snake.draw(&g.button);
    }

    fn grid(_: *Game) void {
        w4.color(0x21);

        for (0..size) |i| {
            for (0..size) |j| {
                const x = (@as(i32, @intCast(i)) * cell);
                const y = (@as(i32, @intCast(j)) * cell);

                w4.rect(x, y, cell, cell);
            }
        }
    }
};

var game = Game{};

export fn start() void {
    game.init();
}

export fn update() void {
    game.update();
    game.draw();
}

fn rect(x: i32, y: i32, c: u16) void {
    w4.color(c);
    w4.rect(x * cell + 1, y * cell + 1, cell - 2, cell - 2);
}

fn set(x: i32, y: i32, c: u16, o: Vec) void {
    w4.color(c);
    w4.rect(x * cell + o.x, y * cell + o.y, 1, 1);
}

fn text(comptime fmt: []const u8, x: i32, y: i32, args: anytype) void {
    var buf: [100]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, fmt, args) catch @panic("Oh noes!");
    w4.text(str, x, y);
}
