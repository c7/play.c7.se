const w4 = @import("w4");
const sfx = @import("sfx.zig");

const title = "STONE,SCROLL,SHEARS";

// Colors from the Aerugo Palette
// https://lospec.com/palette-list/aerugo
const aerugo: [4]u32 = .{
    0x343230, // Dark gray (background)
    0xffffff, // White (text/symbols)
    0x64a1c2, // Cyan (player highlight)
    0x95392c, // Red (enemy highlight)
};

const Screen = enum {
    Title,
    Mode,
    Game,
    Repeat,
};

const Game = struct {
    screen: Screen = .Title,
    frame: u32 = 0,
    notes: u32 = 0,
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
        if (g.mouse.released(w4.MOUSE_RIGHT)) g.music_enabled = !g.music_enabled;

        switch (g.screen) {
            .Title => if (g.button.released(0, w4.BUTTON_1)) g.change(.Mode),
            .Mode => if (g.button.released(0, w4.BUTTON_1)) g.change(.Game),
            .Game => if (g.button.released(0, w4.BUTTON_1)) g.change(.Repeat),
            .Repeat => if (g.button.released(0, w4.BUTTON_1)) g.change(.Title),
        }

        g.frame += 1;
    }

    fn draw(g: *Game) void {
        const f: i32 = @intCast(g.frame);

        switch (g.screen) {
            .Title => {
                const y: i32 = if (f < 60) f else 60;
                w4.color(0x2);
                w4.text(title, 5, y);
            },
            .Mode => {
                w4.color(0x2);
                w4.text(title, 5, 60);

                w4.color(0x3);
                w4.text("MODE", 5, 85);
            },
            .Game => {
                w4.color(0x2);
                w4.text(title, 5, 60);

                w4.color(0x4);
                w4.text("GAME", 5, 85);
            },
            .Repeat => {
                w4.color(0x2);
                w4.text(title, 5, 60);

                w4.color(0x2);
                w4.text("REPEAT", 5, 85);
            },
        }
    }

    fn change(g: *Game, s: Screen) void {
        if (s == .Title) g.reset() else sfx.toneWinSequence();

        g.screen = s;
    }

    fn music(self: *Game) void {
        const speed: u32 = 12;

        if (self.frame % speed == 0) {
            if ((self.notes / sfx.bass_notes.len) % 7 != 6) {
                w4.tone(
                    sfx.bass_notes[self.notes % sfx.bass_notes.len] / 8,
                    sfx.duration(0, 0, speed - 3, 1),
                    48,
                    w4.TONE_TRIANGLE,
                );
            }

            if (self.notes >= sfx.rhythm_notes.len / 8) {
                const cycle = self.notes / sfx.rhythm_notes.len;

                if (cycle % 2 == 0) {
                    w4.tone(
                        sfx.lead_notes[self.notes % sfx.lead_notes.len],
                        sfx.duration(0, 0, speed - 2, 4),
                        12,
                        w4.TONE_PULSE2,
                    );
                } else {
                    w4.tone(
                        sfx.rhythm_notes[self.notes % sfx.rhythm_notes.len],
                        sfx.duration(2, 1, speed - 2, 2),
                        12,
                        w4.TONE_PULSE2,
                    );
                }
            }

            self.notes += 1;
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
