const w4 = @import("w4");

pub fn score(vol: i32) void {
    w4.tone(frequency(40, 930), duration(0, 0, 15, 0), volume(92, vol), flags(2, 0, 0));
}

pub fn aiOn(vol: i32) void {
    w4.tone(frequency(150, 90), duration(0, 0, 15, 0), volume(92, vol), flags(1, 0, 0));
}

pub fn aiOff(vol: i32) void {
    w4.tone(frequency(80, 150), duration(0, 0, 15, 0), volume(92, vol), flags(1, 0, 0));
}

pub fn crash(vol: i32) void {
    w4.tone(frequency(360, 90), duration(0, 0, 5, 0), volume(42, vol), flags(2, 0, 0));
}

pub fn move(vol: i32) void {
    w4.tone(frequency(40, 20), duration(0, 10, 10, 0), volume(8, vol), flags(2, 0, 0));
}

fn frequency(freq1: i32, freq2: i32) u32 {
    return @intCast(freq1 | (freq2 << 16));
}

fn duration(attack: i32, decay: i32, sustain: i32, release: i32) u32 {
    return @intCast((attack << 24) | (decay << 16) | sustain | (release << 8));
}

fn volume(peak: i32, vol: i32) u32 {
    return @intCast((peak << 8) | vol);
}

fn flags(channel: i32, mode: i32, pan: i32) u32 {
    return @intCast(channel | (mode << 2) | (pan << 4));
}
