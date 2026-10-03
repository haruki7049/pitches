//! 12-tone equal temperament tuning referenced to A4.

const std = @import("std");
const Pitch = @import("./pitch.zig");

const Self = @This();

/// Frequency of A4 in Hz, such as 440.0 (the default), 442.0 or 432.0.
/// It must be positive and finite; `freq` does not check it.
a4: f64 = 440.0,

/// Frequency in Hz: `a4 * 2^((midi - 69) / 12)`.
///
/// Each semitone multiplies the frequency by `2^(1/12)` and each octave doubles it. The result
/// carries the rounding of one `f64` power, a relative error of about `1e-15`.
pub fn freq(self: Self, pitch: Pitch) f64 {
    const semitones_from_a4: f64 = @as(f64, @floatFromInt(pitch.midi())) - 69.0;
    return self.a4 * std.math.pow(f64, 2.0, semitones_from_a4 / 12.0);
}

/// MIDI numbers C0 (12) through B9 (131), as a half-open range.
const test_range = .{ 12, 132 };

test "freq at A4 = 440 Hz against reference values" {
    const et: Self = .{};
    // A4 is the reference itself.
    try std.testing.expectEqual(@as(f64, 440.0), et.freq(.{ .code = .a, .octave = 4 }));
    // A0 = 440 * 2^(-48/12) = 440 / 16 = 27.5 Hz, exactly
    try std.testing.expectEqual(@as(f64, 27.5), et.freq(.{ .code = .a, .octave = 0 }));
    // The values below are 440 * 2^(k/12) computed with `bc -l` at 40 digits.
    // C0: k = -57
    try std.testing.expectApproxEqRel(@as(f64, 16.351597831287414667), et.freq(.{ .code = .c, .octave = 0 }), 1e-14);
    // G3: k = -14
    try std.testing.expectApproxEqRel(@as(f64, 195.99771799087463), et.freq(.{ .code = .g, .octave = 3 }), 1e-14);
    // C4: k = -9
    try std.testing.expectApproxEqRel(@as(f64, 261.62556530059863467), et.freq(.{ .code = .c, .octave = 4 }), 1e-14);
    // C8: k = 39
    try std.testing.expectApproxEqRel(@as(f64, 4186.0090448095781548), et.freq(.{ .code = .c, .octave = 8 }), 1e-14);
    // B9: k = 62
    try std.testing.expectApproxEqRel(@as(f64, 15804.265640195971578), et.freq(.{ .code = .b, .octave = 9 }), 1e-14);
}

test "freq follows a 442 Hz reference" {
    const et: Self = .{ .a4 = 442.0 };
    try std.testing.expectEqual(@as(f64, 442.0), et.freq(.{ .code = .a, .octave = 4 }));
    // A5 = 442 * 2^(12/12) = 884 Hz, exactly
    try std.testing.expectEqual(@as(f64, 884.0), et.freq(.{ .code = .a, .octave = 5 }));
}

test "freq follows a 432 Hz reference" {
    const et: Self = .{ .a4 = 432.0 };
    try std.testing.expectEqual(@as(f64, 432.0), et.freq(.{ .code = .a, .octave = 4 }));
    // A3 = 432 * 2^(-12/12) = 216 Hz, exactly
    try std.testing.expectEqual(@as(f64, 216.0), et.freq(.{ .code = .a, .octave = 3 }));
    // C4 = 432 * 2^(-9/12) = 256.8687368405877504 Hz (`bc -l`)
    try std.testing.expectApproxEqRel(@as(f64, 256.86873684058775041), et.freq(.{ .code = .c, .octave = 4 }), 1e-14);
    // C0 = 432 * 2^(-57/12) = 16.0542960525367344 Hz (`bc -l`)
    try std.testing.expectApproxEqRel(@as(f64, 16.054296052536734401), et.freq(.{ .code = .c, .octave = 0 }), 1e-14);
}

test "freq scales linearly with the reference" {
    // Every pitch at 432 Hz is 432 / 440 of the same pitch at 440 Hz.
    const et440: Self = .{};
    const et432: Self = .{ .a4 = 432.0 };
    for (test_range[0]..test_range[1]) |n| {
        const p = try Pitch.fromMidi(n);
        try std.testing.expectApproxEqRel(et440.freq(p) * (432.0 / 440.0), et432.freq(p), 1e-14);
    }
}

test "adjacent semitones differ by 2^(1/12)" {
    // 2^(1/12) = 1.0594630943592952646 (`bc -l`)
    const ratio: f64 = 1.0594630943592952646;
    inline for (.{ 440.0, 432.0 }) |a4| {
        const et: Self = .{ .a4 = a4 };
        for (test_range[0]..test_range[1] - 1) |n| {
            const lower = et.freq(try Pitch.fromMidi(n));
            const upper = et.freq(try Pitch.fromMidi(n + 1));
            try std.testing.expectApproxEqRel(ratio, upper / lower, 1e-14);
        }
    }
}

test "each octave doubles the frequency" {
    inline for (.{ 440.0, 432.0 }) |a4| {
        const et: Self = .{ .a4 = a4 };
        for (test_range[0]..test_range[1] - 12) |n| {
            const lower = et.freq(try Pitch.fromMidi(n));
            const upper = et.freq(try Pitch.fromMidi(n + 12));
            try std.testing.expectApproxEqRel(@as(f64, 2.0), upper / lower, 1e-14);
        }
    }
}

test "freq rises strictly with the MIDI number" {
    const et: Self = .{};
    var previous: f64 = 0.0;
    for (test_range[0]..test_range[1]) |n| {
        const current = et.freq(try Pitch.fromMidi(n));
        try std.testing.expect(current > previous);
        previous = current;
    }
}

test {
    std.testing.refAllDecls(@This());
}
