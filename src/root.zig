//! Pitch names, transposition and tuning.
//!
//! Every public name states the pitch system it belongs to (`TwelveTone...`), so that other
//! systems, such as 19-EDO or just intonation, can sit beside it without taking over a generic name.

const std = @import("std");

/// Twelve-tone pitch: one of the 12 pitch classes (`TwelveTonePitch.Code`) and an octave.
pub const TwelveTonePitch = @import("./twelve-tone-pitch.zig");
/// Twelve-tone equal temperament (12-TET) tuning referenced to A4.
pub const TwelveToneEqualTemperament = @import("./twelve-tone-equal-temperament.zig");

test {
    std.testing.refAllDecls(@This());
}
