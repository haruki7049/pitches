# pitches

Pitch names, transposition and tuning in Zig

Pure Zig with no dependencies beyond `std`. Requires Zig `0.16.0`.

A pitch is only a name (pitch class and octave). It holds no tuning: a tuning resolves it to a frequency. Every type
names the pitch system it belongs to, so other systems (such as 19-EDO or just intonation) can be added beside the
twelve-tone ones.

## Provided types

| Symbol | Description |
| :--- | :--- |
| `TwelveTonePitch` | Pitch class `code` (`TwelveTonePitch.Code`: `c`, `cs`, ... `b`; sharps only) and `octave` (`i8`), with `midi`, `fromMidi`, `add` (transpose by semitones), `lowest` and `highest` |
| `TwelveToneEqualTemperament` | Twelve-tone equal temperament (12-TET) referenced to `a4` (defaults to 440 Hz), with `freq` |

A `TwelveTonePitch` spans C-128 to B127. Its MIDI note number (`midi`, an `i16`) extends the MIDI range 0-127 in both
directions, from -1524 to 1547, so C-1 is 0 and negative octaves reach sub-audio frequencies. `fromMidi` and `add`
return `error.PitchOutOfRange` outside that range.

## Usage

```sh
zig fetch --save git+https://github.com/haruki7049/pitches
```

```zig
// build.zig
const pitches = b.dependency("pitches", .{ .target = target, .optimize = optimize });
mod.addImport("pitches", pitches.module("pitches"));
```

```zig
const pitches = @import("pitches");

// Shorter local names are up to the consumer.
const Pitch = pitches.TwelveTonePitch;
const Tuning = pitches.TwelveToneEqualTemperament;

const tuning: Tuning = .{}; // A4 = 440 Hz
const c4: Pitch = .{ .code = .c, .octave = 4 };

const hz = tuning.freq(c4); // 261.63 Hz
const c5 = try c4.add(12); // C5
```

## Development

```sh
zig build test
```

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or [MIT license](LICENSE-MIT) at your option.
