# OctagonShape

Low-level octagon shape primitive (straight-corner variant): a border ring plus an
interior fill, with precise hit testing. It is a `Shape` that consumes an externally
injected `QoolBoxShapeControl` and renders the octagon from its control points. It is
used by `QoolBox` for assembly; instantiating it directly is only self-consistent when
a `control` is injected, since the type deliberately does not hold its own geometry.

This is a low-level composition component (not a self-sufficient standalone control).
The entire `QoolBoxShapeControl` must be injected through the required `control`
property; the type is a pure consumer of the control points, space and settings and
owns no geometry. Styling is read through `control.settings`. The four corner cuts are
configured independently via `settings.cutSizeTL`/`cutSizeTR`/`cutSizeBL`/`cutSizeBR`.

## Properties

- `control` (required, `QoolBoxShapeControl`): the octagon control-point computation
  source. It is `required` — the host must inject it (used by `QoolBox` for assembly).
- `fillItem` (alias, `Item`): any `Item` filled into the octagon's interior region
  (Qt 6.8 `ShapePath::fillItem`). The fill source must be a texture-capable item such
  as an `Image` or a `ShaderEffectSource`; an ordinary item tree needs layered
  rendering (for example a `ShaderEffectSource`) to be textureable.
- `fillGradient` (alias, `ShapeGradient`): the gradient fill channel. Default `null`
  (solid color); `fillItem` takes priority over the gradient. Note that
  `ShapePath::fillGradient` requires the new `ShapeGradient` API (`LinearGradient` and
  friends); the legacy `Gradient` type is not usable.

## Signals

This type defines no additional signals. (It inherits the standard `Shape`/`Item`
signals.)

## Methods

This type defines no additional methods.

## Usage Example

Used by `QoolBox` as the straight-corner rendering variant. Standalone use requires
injecting a `control`:

```qml
import QtQuick
import QtQuick.Shapes
import Qool

OctagonShape {
    id: shape
    width: 200
    height: 120
    control: QoolBoxShapeControl {
        target: shape
        settings: QoolBoxSettings {
            cutSizeTL: 20
            cutSizeTR: 20
            cutSizeBL: 20
            cutSizeBR: 20
            borderWidth: 2
            borderColor: "white"
            fillColor: "black"
        }
    }
}
```
