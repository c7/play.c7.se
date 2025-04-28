const w4 = @import("w4");
const sfx = @import("sfx.zig");

const title = "42!";

// Colors from the Aerugo Palette
// https://lospec.com/palette-list/aerugo
const aerugo: [4]u32 = .{
    0x343230, // Dark gray (background)
    0xffffff, // White ()
    0x64a1c2, // Cyan ()
    0x87d1ef, // Baby blue ()
};

const Screen = enum {
    Birthday,
};

const Game = struct {
    screen: Screen = .Birthday,
    frame: u32 = 0,
    notes: u32 = 0,
    total: [2]u32 = .{ 0, 0 },
    palette: [4]u32 = aerugo,
    mouse: w4.Mouse = .{},
    button: w4.Button = .{},
    music_enabled: bool = true,

    fn reset(g: *Game) void {
        g.frame = 0;
        g.notes = 0;
    }

    fn start(g: *Game) void {
        w4.palette(g.palette);
    }

    fn update(g: *Game) void {
        g.mouse.update();
        g.button.update();

        if (g.music_enabled) g.music();
        if (g.mouse.released(w4.MOUSE_LEFT)) g.reset();
        // if (g.mouse.released(w4.MOUSE_RIGHT)) g.music_enabled = !g.music_enabled;

        g.frame += 1;
    }

    fn draw(g: *Game) void {
        const f: i32 = @intCast(g.frame);

        switch (g.screen) {
            .Birthday => g.birthday(f),
        }
    }

    fn birthday(g: *Game, f: i32) void {
        const rx: i32 = @intCast(g.total[0] % 160);
        const ry: i32 = @intCast(g.total[1] % 160);

        if (rx != 0 and ry != 0) {
            const r1: u32 = @intCast(@divExact(ry + rx, 6));

            w4.color(0x43);
            w4.circle(rx, ry, r1);

            w4.line(0, 0, rx, ry);
            w4.line(160, 0, rx, ry);
            w4.line(0, 160, rx, ry);
            w4.line(160, 160, rx, ry);

            w4.color(0x41);
            w4.circle(rx, ry, @intCast(@divExact(ry + rx, 9)));
        }

        const y: i32 = if (f < 60) f else 60;
        w4.color(0x2);
        w4.text(title, 5, y);
    }

    fn change(g: *Game, s: Screen) void {
        if (s == .Title) g.reset() else sfx.toneWinSequence();

        g.screen = s;
    }

    fn music(g: *Game) void {
        const speed: u32 = 12;

        if (g.frame % speed == 0) {
            if ((g.notes / sfx.bass_notes.len) % 7 != 6) {
                const vol = 48;
                const dur = sfx.duration(0, 0, speed - 3, 1);

                w4.tone(
                    sfx.bass_notes[g.notes % sfx.bass_notes.len] / 8,
                    dur,
                    vol,
                    w4.TONE_TRIANGLE,
                );

                g.total[0] += vol;
                g.total[1] += dur;
            }

            if (g.notes >= sfx.rhythm_notes.len / 8) {
                const cycle = g.notes / sfx.rhythm_notes.len;
                const vol = 12;

                if (cycle % 2 == 0) {
                    const dur = sfx.duration(0, 0, speed - 2, 4);

                    w4.tone(
                        sfx.lead_notes[g.notes % sfx.lead_notes.len],
                        dur,
                        vol,
                        w4.TONE_PULSE2,
                    );

                    g.total[0] += vol;
                    g.total[1] += dur;
                } else {
                    const dur = sfx.duration(2, 1, speed - 2, 2);
                    w4.tone(
                        sfx.rhythm_notes[g.notes % sfx.rhythm_notes.len],
                        dur,
                        vol,
                        w4.TONE_PULSE2,
                    );

                    g.total[0] += vol;
                    g.total[1] += dur;
                }
            }

            g.notes += 1;
        }
    }
};

var game: Game = .{};

export fn start() void {
    game.start();
}

export fn update() void {
    game.update();
    game.draw();
}
