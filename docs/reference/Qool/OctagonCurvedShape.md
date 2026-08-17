# OctagonCurvedShape

Low-level octagon shape primitive (rounded-corner variant): a border ring plus an
interior fill. Like `OctagonShape` it is a `Shape` that consumes an externally injected
`QoolBoxShapeControl` and owns no geometry. It was formerly named `OctagonRoundedShape`
(renamed to align with `settings.curved`).

## Properties

- `control` (required, `QoolBoxShapeControl`): the octagon control-point computation
  source. It is `required` — the host must inject it (used by `QoolBox` for assembly).
- `fillItem` (alias, `Item`): any `Item` filled into the octagon's interior region
  (Qt 6.8 `ShapePath::fillItem`). Same semantics as `OctagonShape` — the fill source
  must be texture-capable (for example `Image` or `ShaderEffectSource`).
- `fillGradient` (alias, `ShapeGradient`): the gradient fill channel. Default `null`
  (solid color); `fillItem` takes priority over the gradient. `ShapePath::fillGradient`
  requires the new `ShapeGradient` API (`LinearGradient` and friends); the legacy
  `Gradient` type is not usable.

## Corner radius

The outer arc radius equals the corresponding corner `cut*` in `control.settings`
(`cutSizeTR` for the top-right corner, and so on). The inner arc radius is derived by
the `Shape` itself from the inner-ring adjacent-point chord length divided by √2
(the control does not provide a derived property). When `cut` is 0 the chord is 0 and
the radius is 0 — a degenerate but self-consistent form.

## Hit testing

The path uses `containsMode: Shape.FillContains` — hit testing is by path-fill
judgment, giving precise rounded-corner hits (no linear-inequality judgment).

## Signals

This type defines no additional signals. (It inherits the standard `Shape`/`Item`
signals.)

## Methods

This type defines no additional methods.

## Usage Example

Used by `QoolBox` as the rounded-corner rendering variant. Standalone use requires
injecting a `control`:

```qml
import QtQuick
import QtQuick.Shapes
import Qool

OctagonCurvedShape {
    id: shape
    width: 200
    height: 120
    control: QoolBoxShapeControl {
        target: shape
        settings: QoolBoxSettings {
            cutSizeTL: 24
            cutSizeTR: 24
            cutSizeBL: 24
            cutSizeBR: 24
            borderWidth: 2
            borderColor: "white"
            fillColor: "black"
            curved: true
        }
    }
}
```
