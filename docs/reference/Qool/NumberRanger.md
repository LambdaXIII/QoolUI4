# NumberRanger

A numeric range-validation utility: clamps values against an optional
`[bottom, top]` range, rounds them to a configurable decimal precision, and
formats numbers embedded in strings. It is typically used to keep user or
model input inside a valid numeric interval (e.g. a temperature dial between
0 and 100, a zoom factor between 1 and 5) while normalizing the displayed
precision.

NumberRanger validates against a pair of optional bounds (`top` and
`bottom`). Each bound is active only when it holds a numeric (qreal-
convertible) value; a null or non-numeric bound is ignored. Active bounds
are themselves precision-rounded with the current `decimals` before any
comparison — clamping always happens against the rounded bound, not the raw
property value. Which bounds participate is controlled by `validateMode`.

`NumberRanger` inherits `SmartObject`, so it also provides `smartItems`
(default property), `parent`, and `dumpProperties()`.

## Enum: ValidateModes

Controls which bounds take part in validation.

- `AutoValidate` (`0`, default)
  Both `top` and `bottom` are active.

- `IgnoreTop` (`1`)
  `top` is inactive; `bottom` remains active.

- `IgnoreBottom` (`2`)
  `bottom` is inactive; `top` remains active.

- `None` (`-1`)
  Both bounds are inactive; validation never clamps.

## Properties

- `top : QVariant` (read/write, default null)
  Upper bound candidate. Active when it holds a numeric value; the rounded
  bound is `round`ed to `decimals` places. `null` or non-numeric values make
  the bound inactive.

- `bottom : QVariant` (read/write, default null)
  Lower bound candidate, symmetric to `top`.

- `decimals : int` (read/write, default `3`)
  Decimal precision used by rounding. With `decimals < 0` values are left
  unchanged; with `decimals == 0` values are rounded to the nearest integer
  (`std::round`, half away from zero); with `decimals > 0` values are
  rounded to that many fractional digits (`math::set_precision`, same
  rounding mode). Changing it re-validates the bounds and all tracked
  inputs.

- `validateMode : ValidateModes` (read/write, default `AutoValidate`)
  Selects which bounds participate in validation, as described above.
  Changing it re-evaluates the active bounds and all tracked inputs.

- `inputN : QVariant` (read/write, N in `0..9`, default null)
  Ten independently tracked input slots. Each slot is continuously
  validated into the matching `validatedN`.

- `validatedN : QVariant` (read-only, N in `0..9`, default null)
  The validated mirror of `inputN`. If the input is null or not
  qreal-convertible, `validatedN` holds the input value unchanged;
  otherwise it holds the precision-rounded input clamped to the active
  rounded bounds (same rule as `validate()`). Updated whenever `inputN`,
  `decimals`, `validateMode`, `top`, or `bottom` changes.

All properties are bindable and notify through the corresponding
`*Changed` signals.

## Signals

- `topChanged()`, `bottomChanged()`, `decimalsChanged()`,
  `validateModeChanged()`, `inputNChanged()`, `validatedNChanged()`
  Emitted when the corresponding property value changes.

## Methods

- `validate(number : QVariant) : QVariant`
  Validates an arbitrary value. `null` and non-qreal-convertible inputs are
  returned unchanged. Otherwise the value is converted to a number, rounded
  with `decimals`, then clamped to the active rounded bounds: if it exceeds
  `top` the rounded top bound is returned, if it falls below `bottom` the
  rounded bottom bound is returned, otherwise the rounded value itself is
  returned. Bounds are inclusive — a value exactly equal to a bound passes.
  Note that a `QVariant` holding a `QString` always reports itself as
  qreal-convertible (Qt conversion rule): non-numeric strings convert to
  `0.0` and are validated as `0.0` rather than passed through.

- `validatePrecision(number : QVariant) : QVariant`
  Rounds without clamping. `null` and non-qreal-convertible inputs are
  returned unchanged; everything else is returned as its `decimals`-rounded
  value.

- `format(v : QVariant) : QVariant`
  Formats a value as text. `null` is returned unchanged. Any value that can
  convert to `QString` (all built-in numbers and strings) takes the string
  path: every numeric token matching `\d+(\.\d+)?` (digits with an optional
  fractional part; no sign or exponent) is replaced by
  `QString::number(decimalfy(token))` — the token precision-rounded to
  `decimals` and emitted with `QString`'s default formatting (no fixed
  width, no padding). The result is always a `QString` variant, even for
  numeric inputs. Values without a `QString` conversion but with a `qreal`
  conversion are returned as `QString::number(decimalfy(value))`; any other
  value is returned unchanged.
  Tokens are applied as whole-string replacements in lexicographic order of
  the original token text, so when one token's text appears inside another
  token's text in the same string (e.g. both `1` and `1.5` present), the
  earlier replacement can rewrite part of the later token.

## Usage Example

```qml
import QtQuick
import Qool

// A 0..100 range with one decimal place, and three tracked inputs.
NumberRanger {
    id: ranger
    top: 100
    bottom: 0
    decimals: 1
    // validateMode defaults to AutoValidate

    input0: 12.34   // validated0 -> 12.3
    input1: -3      // validated1 -> 0
    input2: 250     // validated2 -> 100
}

// Elsewhere:
// ranger.validate(7.77)            // -> 7.8
// ranger.validate(300)             // -> 100
// ranger.validatePrecision(1.234)  // -> 1.2
// ranger.format("x=1.23456")       // -> "x=1.2"
```
