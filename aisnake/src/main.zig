const w4 = @import("w4");
const std = @import("std");
const sfx = @import("sfx.zig");

const DELAY = 4;
const SIZE = 20; // 20 or 32
const CELL = w4.SCREEN_SIZE / SIZE;
const N = SIZE * SIZE;

const Snake = struct {
    x: u8 = 0,
    y: u8 = 0,
    d: u2 = 0,

    score: Score = .{},

    nodes: [N]Node = undefined,
    head: usize = 0,
    tail: usize = 0,

    fn crash(s: *Snake) void {
        sfx.crash(100);

        s.init();
    }

    fn init(s: *Snake) void {
        s.x = @mod(random.int(u8), (SIZE / 2)) + (SIZE / 4);
        s.y = @mod(random.int(u8), (SIZE / 2)) + (SIZE / 4);
        s.d = random.int(u2);

        s.nodes = .{Node.init(s.x, s.y, s.d)} ** N;
        s.head = 0;
        s.tail = 0;

        s.score.init();
    }

    fn eat(s: *Snake, a: *Apple) bool {
        const h = &s.nodes[s.head];

        return h.x == a.x and h.y == a.y;
    }

    pub fn length(s: Snake) usize {
        return ((s.head + N + 1) - s.tail) % N;
    }

    pub fn iter(self: *const Snake) Iter {
        return .{ .snake = self, .i = self.tail };
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
            if (s.x < 0 or s.x >= SIZE or s.y < 0 or s.y >= SIZE) {
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
            0 => s.y -= 1,
            1 => s.y += 1,
            2 => s.x -= 1,
            3 => s.x += 1,
        }

        s.moveHead(s.d);
    }

    fn moveHead(self: *Snake, d: u2) void {
        const h = &self.nodes[self.head];

        self.head = (self.head + 1) % N;
        self.nodes[self.head] = h.copy(d);
    }

    fn moveTail(s: *Snake) void {
        s.tail = (s.tail + 1) % N;
    }

    fn left(s: *Snake) void {
        s.d = switch (s.d) {
            0 => 2,
            1 => 3,
            2 => 1,
            3 => 0,
        };
    }

    fn right(s: *Snake) void {
        s.d = switch (s.d) {
            0 => 3,
            1 => 2,
            2 => 0,
            3 => 1,
        };
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
            0 => switch (t) {
                .forward => ty -= 1,
                .left => tx -= 1,
                .right => tx += 1,
            },
            1 => switch (t) {
                .forward => ty += 1,
                .left => tx += 1,
                .right => tx -= 1,
            },
            2 => switch (t) {
                .forward => tx -= 1,
                .left => ty += 1,
                .right => ty -= 1,
            },
            3 => switch (t) {
                .forward => tx += 1,
                .left => ty -= 1,
                .right => ty += 1,
            },
        }

        var reward: i32 = 0;

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
        rect(s.x, s.y, 3);

        var it = s.iter();

        while (it.next()) |n| {
            const i = (it.i + N - 1) % N;

            rect(n.x, n.y, 3);

            if (i == s.head) {
                set(s.x, s.y, 1, switch (s.d) {
                    0 => .{ .x = CELL / 2, .y = 1 },
                    1 => .{ .x = CELL / 2, .y = CELL - 2 },
                    2 => .{ .x = 1, .y = CELL / 2 },
                    3 => .{ .x = CELL - 2, .y = CELL / 2 },
                });
            } else {
                set(n.x, n.y, 1, switch (n.d) {
                    1 => .{ .x = CELL / 2, .y = 1 },
                    0 => .{ .x = CELL / 2, .y = CELL - 2 },
                    3 => .{ .x = 1, .y = CELL / 2 },
                    2 => .{ .x = CELL - 2, .y = CELL / 2 },
                });
            }
        }

        s.score.draw(b);
    }
};

const Score = struct {
    now: u16 = 0,
    old: u16 = 0,

    fn init(s: *Score) void {
        if (s.old < s.now) s.old = s.now;

        s.now = 0;
    }

    fn increment(s: *Score) void {
        s.now += if (ai) 1 else 10;

        sfx.score(20);
    }

    fn draw(s: *Score, b: *w4.Button) void {
        w4.color(if (b.held(0, w4.BUTTON_2) or @mod(time, 3) == 0) 4 else 3);
        text("\x86{d}", 2, 2, .{s.old});

        w4.color(if (b.held(0, w4.BUTTON_2) or @mod(time, 3) == 0) 3 else 4);
        text("\x85{d}", 2, 12, .{s.now});
    }
};

const Apple = struct {
    x: u8 = 0,
    y: u8 = 0,

    fn init(a: *Apple, s: *Snake) void {
        a.x = @mod(random.int(u8), SIZE);
        a.y = @mod(random.int(u8), SIZE);

        var it = s.iter();

        while (it.next()) |n| {
            if (a.x == n.x and a.y == n.y) a.init(s);
        }
    }

    fn draw(a: *Apple) void {
        rect(a.x, a.y, 4);

        const x: i32 = @intCast(a.x);
        const y: i32 = @intCast(a.y);

        w4.color(3);
        w4.pixel(x * CELL + CELL / 2, y * CELL);

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

var disk: Disk = .{ .starts = 0 };
var time: i32 = 0;

var apple: Apple = .{};
var snake: Snake = .{};

var ai = true;

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

export fn start() void {
    w4.palette(.{ 0x111111, 0x141414, 0x00FF00, 0xFF0000 });

    _ = disk.increment();

    for (disk.starts) |_| {
        _ = random.intRangeAtMost(usize, disk.starts, disk.starts + disk.starts);
    }

    snake.init();
    apple.init(&snake);
}

fn input() void {
    if (button.pressed(0, w4.BUTTON_UP)) snake.d = 0;
    if (button.pressed(0, w4.BUTTON_DOWN)) snake.d = 1;
    if (button.pressed(0, w4.BUTTON_LEFT)) snake.d = 2;
    if (button.pressed(0, w4.BUTTON_RIGHT)) snake.d = 3;
    if (button.released(0, w4.BUTTON_1)) ai = !ai;
}

fn draw() void {
    grid();
    apple.draw();
    snake.draw(&button);
}

export fn update() void {
    button.update();
    input();

    if (ai) {
        w4.PALETTE[3] = 0xFF0000;
        snake.ai(&apple);
    } else {
        w4.PALETTE[3] = 0xFFFF00;
    }

    time += 1;

    if (@mod(time, DELAY) == 0) {
        snake.detect(&apple);
        snake.move();
    }

    draw();
}

fn rect(x: u8, y: u8, c: u16) void {
    w4.color(c);
    w4.rect(@as(i32, @intCast(x)) * CELL + 1, @as(i32, @intCast(y)) * CELL + 1, CELL - 2, CELL - 2);
}

fn set(x: u8, y: u8, c: u16, o: Vec) void {
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

const Node = struct {
    x: u8,
    y: u8,
    d: u2,

    pub fn init(x: u8, y: u8, d: u2) Node {
        return .{ .x = x, .y = y, .d = d };
    }

    fn copy(self: Node, d: u2) Node {
        return switch (d) {
            0 => init(self.x, self.y - 1, d),
            1 => init(self.x, self.y + 1, d),
            2 => init(self.x - 1, self.y, d),
            3 => init(self.x + 1, self.y, d),
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
