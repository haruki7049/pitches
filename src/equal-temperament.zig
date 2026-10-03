//! 12-tone equal temperament tuning referenced to A4.

const std = @import("std");
const Pitch = @import("./pitch.zig");

const Self = @This();

/// Frequency of A4 in Hz.
a4: f64 = 440.0,

/// Frequency in Hz: `a4 * 2^((midi - 69) / 12)`.
pub fn freq(self: Self, pitch: Pitch) f64 {
    const semitones_from_a4: f64 = @as(f64, @floatFromInt(pitch.midi())) - 69.0;
    return self.a4 * std.math.pow(f64, 2.0, semitones_from_a4 / 12.0);
}

test "freq at A4 = 440 Hz" {
    const et: Self = .{};
    try std.testing.expectEqual(@as(f64, 440.0), et.freq(.{ .code = .a, .octave = 4 }));
    // G3 = 440 * 2^(-14/12) = 195.998 Hz
    try std.testing.expectApproxEqRel(@as(f64, 195.998), et.freq(.{ .code = .g, .octave = 3 }), 1e-4);
    // C7 = 440 * 2^(27/12) = 2093.005 Hz
    try std.testing.expectApproxEqRel(@as(f64, 2093.005), et.freq(.{ .code = .c, .octave = 7 }), 1e-4);
}

test "freq follows the reference" {
    const et: Self = .{ .a4 = 442.0 };
    try std.testing.expectEqual(@as(f64, 442.0), et.freq(.{ .code = .a, .octave = 4 }));
    try std.testing.expectEqual(@as(f64, 884.0), et.freq(.{ .code = .a, .octave = 5 }));
}

test {
    std.testing.refAllDecls(@This());
}
