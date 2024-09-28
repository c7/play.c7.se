const w4 = @import("w4");

pub const C = @cImport({
    @cInclude("w4on2.h");
});

pub var runtime: C.w4on2_rt_t = undefined;
pub var player: C.w4on2_player_t = undefined;

pub const song = @embedFile("songs/song.w4on2");

pub fn start() void {
    C.w4on2_rt_init(&runtime, tone, null);
    C.w4on2_player_init(&player, song);
}

pub fn tick() void {
    _ = C.w4on2_player_tick(&player, &runtime);
    C.w4on2_rt_tick(&runtime);
}

fn tone(freq: u32, dur: u32, vol: u32, fl: u32, _: ?*anyopaque) callconv(.C) void {
    w4.tone(freq, dur, vol, fl);
}
