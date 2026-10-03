//! Pitch names, transposition and tuning.

const std = @import("std");

/// 12-tone pitch: pitch class code and octave.
pub const Pitch = @import("./pitch.zig");
/// Pitch class code (`c` through `b`, sharps only).
pub const Code = Pitch.Code;
/// 12-tone equal temperament tuning referenced to A4.
pub const EqualTemperament = @import("./equal-temperament.zig");

test {
    std.testing.refAllDecls(@This());
}
