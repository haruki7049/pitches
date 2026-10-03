//! 12-tone pitch: a pitch class code and an octave. Holds no tuning.

const std = @import("std");

const Self = @This();

/// Pitch class.
code: Code,
/// Octave number in scientific pitch notation (A4 is the A above middle C).
octave: usize,

/// Pitch class codes. The `s` suffix marks a sharp.
pub const Code = enum(u8) { c, cs, d, ds, e, f, fs, g, gs, a, as, b };

/// MIDI note number: `12 * (octave + 1) + code`. C4 is 60 and A4 is 69.
pub fn midi(self: Self) usize {
    return 12 * (self.octave + 1) + @intFromEnum(self.code);
}

/// Returns the pitch of a MIDI note number.
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

test "midi" {
    // C4 = 12 * (4 + 1) + 0 = 60, A4 = 12 * (4 + 1) + 9 = 69, C0 = 12 * (0 + 1) + 0 = 12
    try std.testing.expectEqual(@as(usize, 60), (Self{ .code = .c, .octave = 4 }).midi());
    try std.testing.expectEqual(@as(usize, 69), (Self{ .code = .a, .octave = 4 }).midi());
    try std.testing.expectEqual(@as(usize, 12), (Self{ .code = .c, .octave = 0 }).midi());
}

test "fromMidi is the inverse of midi" {
    for (12..128) |n| try std.testing.expectEqual(n, (try fromMidi(n)).midi());
    try std.testing.expectError(error.PitchOutOfRange, fromMidi(11));
}

test "add" {
    // A4 (69) + 3 = 72 = C5
    const a4 = Self{ .code = .a, .octave = 4 };
    try std.testing.expectEqual(Self{ .code = .c, .octave = 5 }, try a4.add(3));
    // C4 (60) - 1 = 59 = B3
    const c4 = Self{ .code = .c, .octave = 4 };
    try std.testing.expectEqual(Self{ .code = .b, .octave = 3 }, try c4.add(-1));
    // C4 (60) - 48 = 12 = C0, the lowest pitch; one more semitone down is out of range
    try std.testing.expectEqual(Self{ .code = .c, .octave = 0 }, try c4.add(-48));
    try std.testing.expectError(error.PitchOutOfRange, c4.add(-49));
}

test {
    std.testing.refAllDecls(@This());
}
