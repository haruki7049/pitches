# pitches

Pitch names, transposition and tuning in Zig

Pure Zig with no dependencies beyond `std`. Requires Zig `0.16.0`.

A `Pitch` is only a name (pitch class and octave). It holds no tuning: a tuning such as `EqualTemperament`
resolves it to a frequency.

## Provided types

| Symbol | Description |
| :--- | :--- |
| `Pitch` | Pitch class `code` and `octave`, with `midi`, `fromMidi` and `add` (transpose by semitones) |
| `Code` | Pitch class (`c`, `cs`, `d`, ... `b`; sharps only), the same type as `Pitch.Code` |
| `EqualTemperament` | 12-tone equal temperament referenced to `a4` (defaults to 440 Hz), with `freq` |

`fromMidi` and `add` return `error.PitchOutOfRange` below C0 (MIDI 12), since `octave` cannot be negative.

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

const tuning: pitches.EqualTemperament = .{}; // A4 = 440 Hz
const c4: pitches.Pitch = .{ .code = .c, .octave = 4 };

const hz = tuning.freq(c4); // 261.63 Hz
const c5 = try c4.add(12); // C5
```

## Development

```sh
zig build test
```

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or [MIT license](LICENSE-MIT) at your option.
