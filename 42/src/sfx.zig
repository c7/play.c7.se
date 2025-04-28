const w4 = @import("w4");

const C3: u32 = 131;
const D3: u32 = 147;
const E3: u32 = 165;
const F3: u32 = 175;
const G3: u32 = 196;
const A3: u32 = 220;
const B3: u32 = 247;

const C4: u32 = C3 * 2;
const D4: u32 = D3 * 2;
const E4: u32 = E3 * 2;
const F4: u32 = F3 * 2;
const G4: u32 = G3 * 2;
const A4: u32 = A3 * 2;
const B4: u32 = B3 * 2;

const C5: u32 = C4 * 2;
const D5: u32 = D4 * 2;
const E5: u32 = E4 * 2;
const F5: u32 = F4 * 2;
const G5: u32 = G4 * 2;
const A5: u32 = A4 * 2;
const B5: u32 = B4 * 2;

const C6: u32 = C5 * 2;
const D6: u32 = D5 * 2;
const E6: u32 = E5 * 2;
const F6: u32 = F5 * 2;
const G6: u32 = G5 * 2;
const A6: u32 = A5 * 2;
const B6: u32 = B5 * 2;

pub const bass_notes: []const u32 = &[_]u32{
    A4, 0, A4, A4, A4, 0, A4, A4, A4, 0, A4, A4, A4, 0, A4, A4,
    C5, 0, C5, C5, C5, 0, C5, C5, C5, 0, C5, C5, C5, 0, C5, C5,
    D5, 0, D5, D5, D5, 0, D5, D5, D5, 0, D5, D5, D5, 0, D5, D5,
    G4, 0, G4, G4, G4, 0, G4, G4, G4, 0, G4, G4, G4, 0, G4, G4,
};

pub const lead_notes: []const u32 = &[_]u32{
    A4, A4, E4, A4, E5, D5, C5, B4, A4, E4, A4, B4, C5, B4, A4, G4,
    C5, C5, A4, G4, A4, C5, D5, A4, C5, D5, E5, G5, E5, B4, A4, G4,
    D5, D5, C5, B4, A4, A4, G4, A4, B4, E4, G4, A4, B4, C5, A4, G4,
    G4, G4, E4, D4, C4, E4, G4, A4, G4, E4, D4, E4, A4, B4, G4, E4,
};

pub const rhythm_notes: []const u32 = &[_]u32{
    A4, C5, E5, A5, A4, C5, E5, A5, A4, C5, E5, A5, A4, C5, E5, A5,
    C5, E5, G5, C6, C5, E5, G5, C6, C5, E5, G5, C6, C5, E5, G5, C6,
    D5, F5, A5, D6, D5, F5, A5, D6, D5, F5, A5, D6, D5, F5, A5, D6,
    G4, B4, D5, G5, G4, B4, D5, G5, G4, B4, D5, G5, G4, B4, D5, G5,
};

pub fn toneClick() void {
    w4.tone(69, duration(0, 0, 2, 10), 22, w4.TONE_PULSE1 | w4.TONE_NOTE_MODE);
}

pub fn toneBeep() void {
    w4.tone(52, 3, 80, w4.TONE_PULSE1 | w4.TONE_NOTE_MODE | w4.TONE_MODE2);
}

pub fn toneWinSequenceOld() void {
    // Pulse waves play a major triad
    w4.tone(60, 22, 20, w4.TONE_PULSE1 | w4.TONE_NOTE_MODE);
    w4.tone(67, 22, 30, w4.TONE_PULSE2 | w4.TONE_NOTE_MODE);
    w4.tone(76, 22, 40, w4.TONE_PULSE1 | w4.TONE_NOTE_MODE);

    // Noise channel "crunch" (no note mode)
    w4.tone(frequency(80, 20), 4, 40, w4.TONE_NOISE); // Frequency slide: 80Hz → 20Hz
}

pub fn toneWinSequence() void {
    // Arpeggiated major triad (C major: C4-E4-G4)
    w4.tone(60, 20, 15, w4.TONE_PULSE1 | w4.TONE_NOTE_MODE); // C4
    w4.tone(64, 20, 25, w4.TONE_PULSE2 | w4.TONE_NOTE_MODE); // E4
    w4.tone(67, 20, 35, w4.TONE_PULSE1 | w4.TONE_NOTE_MODE); // G4

    // Quick octave jump to finalize (C5)
    w4.tone(72, 30, 30, w4.TONE_PULSE2 | w4.TONE_NOTE_MODE); // C5 (triumphant capstone)

    // Noise channel sparkle at the end
    w4.tone(frequency(100, 10), 15, 30, w4.TONE_NOISE); // Short crackly burst
}

pub fn toneStretch() void {
    w4.tone(frequency(147, 587), 90, 80, w4.TONE_TRIANGLE);
}

pub fn toneShatter() void {
    w4.tone(frequency(1000, 50), 12, 100, w4.TONE_NOISE);
}

pub fn frequency(freq1: i32, freq2: i32) u32 {
    return @intCast(freq1 | (freq2 << 16));
}

pub fn duration(attack: i32, decay: i32, sustain: i32, release: i32) u32 {
    return @intCast((attack << 24) | (decay << 16) | sustain | (release << 8));
}

pub fn volume(peak: i32, vol: i32) u32 {
    return @intCast((peak << 8) | vol);
}

pub fn flags(channel: i32, mode: i32, pan: i32) u32 {
    return @intCast(channel | (mode << 2) | (pan << 4));
}
