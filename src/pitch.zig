//! 12-tone pitch: a pitch class code and an octave. Holds no tuning.

const std = @import("std");

const Self = @This();

/// Pitch class.
code: Code,
/// Octave number in scientific pitch notation: C4 is middle C and A4 is the A above it.
/// The field is unsigned, so the lowest pitch is C0.
octave: usize,

/// Pitch class codes in ascending order, from `c` (0) to `b` (11). The `s` suffix marks a sharp.
pub const Code = enum(u8) { c, cs, d, ds, e, f, fs, g, gs, a, as, b };

/// MIDI note number: `12 * (octave + 1) + code`. C0 is 12, C4 is 60 and A4 is 69.
///
/// The number is not limited to the MIDI range 0-127 (B9 is 131). It overflows when it does not
/// fit in a `usize`, which needs an octave above `maxInt(usize) / 12 - 2`; every pitch that
/// `fromMidi` and `add` return fits.
pub fn midi(self: Self) usize {
    return 12 * (self.octave + 1) + @intFromEnum(self.code);
}

/// Returns the pitch of a MIDI note number, the inverse of `midi`.
/// Numbers above 127 are accepted as well (132 is C10).
/// Returns `error.PitchOutOfRange` below 12 (C0), since `octave` cannot be negative.
pub fn fromMidi(number: usize) error{PitchOutOfRange}!Self {
    if (number < 12) return error.PitchOutOfRange;
    return .{ .code = @enumFromInt(number % 12), .octave = number / 12 - 1 };
}

/// Transposes by `semitones` (negative goes down).
/// Returns `error.PitchOutOfRange` when the result falls below C0, or when its MIDI note number
/// does not fit in a `usize`.
pub fn add(self: Self, semitones: isize) error{PitchOutOfRange}!Self {
    // i128 holds the MIDI number of any octave and the sum with any isize, so nothing overflows.
    const current: i128 = 12 * (@as(i128, self.octave) + 1) + @intFromEnum(self.code);
    const result: i128 = current + semitones;
    if (result < 0 or result > std.math.maxInt(usize)) return error.PitchOutOfRange;
    return fromMidi(@intCast(result));
}

test "midi at reference pitches and range boundaries" {
    // C0 = 12 * (0 + 1) + 0 = 12, the lowest pitch
    try std.testing.expectEqual(@as(usize, 12), (Self{ .code = .c, .octave = 0 }).midi());
    // B0 = 12 * (0 + 1) + 11 = 23
    try std.testing.expectEqual(@as(usize, 23), (Self{ .code = .b, .octave = 0 }).midi());
    // C4 = 12 * (4 + 1) + 0 = 60, middle C
    try std.testing.expectEqual(@as(usize, 60), (Self{ .code = .c, .octave = 4 }).midi());
    // A4 = 12 * (4 + 1) + 9 = 69
    try std.testing.expectEqual(@as(usize, 69), (Self{ .code = .a, .octave = 4 }).midi());
    // G9 = 12 * (9 + 1) + 7 = 127, the top of the MIDI range
    try std.testing.expectEqual(@as(usize, 127), (Self{ .code = .g, .octave = 9 }).midi());
    // B9 = 12 * (9 + 1) + 11 = 131, beyond the MIDI range
    try std.testing.expectEqual(@as(usize, 131), (Self{ .code = .b, .octave = 9 }).midi());
}

test "midi counts codes in ascending semitones within an octave" {
    // Octave 4 starts at 60, so code i is 60 + i.
    for (std.enums.values(Code)) |code| {
        try std.testing.expectEqual(60 + @as(usize, @intFromEnum(code)), (Self{ .code = code, .octave = 4 }).midi());
    }
}

test "fromMidi at range boundaries" {
    try std.testing.expectEqual(Self{ .code = .c, .octave = 0 }, try fromMidi(12));
    try std.testing.expectEqual(Self{ .code = .b, .octave = 0 }, try fromMidi(23));
    try std.testing.expectEqual(Self{ .code = .g, .octave = 9 }, try fromMidi(127));
    // 128 = 12 * (9 + 1) + 8 = G#9, the first number beyond the MIDI range
    try std.testing.expectEqual(Self{ .code = .gs, .octave = 9 }, try fromMidi(128));
    try std.testing.expectEqual(Self{ .code = .b, .octave = 9 }, try fromMidi(131));
    // 132 = 12 * (10 + 1) + 0 = C10
    try std.testing.expectEqual(Self{ .code = .c, .octave = 10 }, try fromMidi(132));
}

test "fromMidi rejects every number below C0" {
    for (0..12) |n| try std.testing.expectError(error.PitchOutOfRange, fromMidi(n));
}

test "midi(fromMidi(n)) is n" {
    for (12..10_000) |n| try std.testing.expectEqual(n, (try fromMidi(n)).midi());
    // The largest numbers a usize holds round-trip as well.
    const max = std.math.maxInt(usize);
    for (max - 100..max) |n| try std.testing.expectEqual(n, (try fromMidi(n)).midi());
    try std.testing.expectEqual(@as(usize, max), (try fromMidi(max)).midi());
}

test "fromMidi(midi(p)) is p" {
    for (0..800) |octave| {
        for (std.enums.values(Code)) |code| {
            const p = Self{ .code = code, .octave = octave };
            try std.testing.expectEqual(p, try fromMidi(p.midi()));
        }
    }
}

test "add moves across octave boundaries" {
    // B3 (59) + 1 = 60 = C4
    try std.testing.expectEqual(Self{ .code = .c, .octave = 4 }, try (Self{ .code = .b, .octave = 3 }).add(1));
    // C4 (60) - 1 = 59 = B3
    try std.testing.expectEqual(Self{ .code = .b, .octave = 3 }, try (Self{ .code = .c, .octave = 4 }).add(-1));
    // A4 (69) + 3 = 72 = C5
    try std.testing.expectEqual(Self{ .code = .c, .octave = 5 }, try (Self{ .code = .a, .octave = 4 }).add(3));
    // E4 (64) - 7 = 57 = A3
    try std.testing.expectEqual(Self{ .code = .a, .octave = 3 }, try (Self{ .code = .e, .octave = 4 }).add(-7));
}

test "add by whole octaves keeps the code" {
    const fs4 = Self{ .code = .fs, .octave = 4 };
    try std.testing.expectEqual(Self{ .code = .fs, .octave = 5 }, try fs4.add(12));
    try std.testing.expectEqual(Self{ .code = .fs, .octave = 3 }, try fs4.add(-12));
    // F#4 (66) + 120 = 186 = 12 * (14 + 1) + 6, F#14
    try std.testing.expectEqual(Self{ .code = .fs, .octave = 14 }, try fs4.add(120));
    // F#4 (66) - 48 = 18 = 12 * (0 + 1) + 6, F#0
    try std.testing.expectEqual(Self{ .code = .fs, .octave = 0 }, try fs4.add(-48));
}

test "add by zero is the identity" {
    for (std.enums.values(Code)) |code| {
        const p = Self{ .code = code, .octave = 4 };
        try std.testing.expectEqual(p, try p.add(0));
    }
}

test "add(n) then add(-n) returns the original pitch" {
    const c4 = Self{ .code = .c, .octave = 4 };
    // C4 is 60, so every n in [-48, 48] stays at or above C0 (12).
    var n: isize = -48;
    while (n <= 48) : (n += 1) {
        try std.testing.expectEqual(c4, try (try c4.add(n)).add(-n));
    }
}

test "add reaches C0 but not below it" {
    // C4 (60) - 48 = 12 = C0
    try std.testing.expectEqual(Self{ .code = .c, .octave = 0 }, try (Self{ .code = .c, .octave = 4 }).add(-48));
    try std.testing.expectError(error.PitchOutOfRange, (Self{ .code = .c, .octave = 4 }).add(-49));
    // C0 (12) - 1 = 11
    try std.testing.expectError(error.PitchOutOfRange, (Self{ .code = .c, .octave = 0 }).add(-1));
    // C#0 (13) - 1 = 12 = C0, - 2 = 11
    try std.testing.expectEqual(Self{ .code = .c, .octave = 0 }, try (Self{ .code = .cs, .octave = 0 }).add(-1));
    try std.testing.expectError(error.PitchOutOfRange, (Self{ .code = .cs, .octave = 0 }).add(-2));
    // B0 (23) - 11 = 12 = C0, - 12 = 11
    try std.testing.expectEqual(Self{ .code = .c, .octave = 0 }, try (Self{ .code = .b, .octave = 0 }).add(-11));
    try std.testing.expectError(error.PitchOutOfRange, (Self{ .code = .b, .octave = 0 }).add(-12));
    // Far below zero, past where an isize sum would overflow
    try std.testing.expectError(error.PitchOutOfRange, (Self{ .code = .c, .octave = 4 }).add(std.math.minInt(isize)));
}

test "add rejects results beyond the largest MIDI number a usize holds" {
    const max = std.math.maxInt(usize);
    const top = try fromMidi(max);
    try std.testing.expectEqual(top, try top.add(0));
    try std.testing.expectError(error.PitchOutOfRange, top.add(1));
    try std.testing.expectEqual(try fromMidi(max - 1), try top.add(-1));
    // An octave whose MIDI number does not fit in a usize at all
    try std.testing.expectError(error.PitchOutOfRange, (Self{ .code = .b, .octave = max / 12 }).add(0));
}

test "add by the largest isize does not overflow" {
    // C4 (60) + maxInt(isize) exceeds an isize but still fits in a usize.
    const c4 = Self{ .code = .c, .octave = 4 };
    const result = try c4.add(std.math.maxInt(isize));
    try std.testing.expectEqual(@as(usize, 60) + std.math.maxInt(isize), result.midi());
}

test {
    std.testing.refAllDecls(@This());
}
