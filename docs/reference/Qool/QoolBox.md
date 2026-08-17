# QoolBox

An octagon background box: shape rendering, content-inset layout quantities, and
precise hit testing. By default it renders an octagon (`OctagonShape`/`OctagonCurvedShape`,
switched between straight and rounded corners via `settings.curved`). Its appearance
is configured uniformly through `settings` (`QoolBoxSettings`): the four corner cuts,
border, fill, offset, and the rounded-corner switch. Styling defaults follow `Style`
(`controlBorderWidth`/`accent`/`dark`), and individual fields can be overridden.

## Properties

- `settings` (`QoolBoxSettings`): the appearance settings (four corner cuts, border,
  fill, offset, rounded switch). Default is a `QoolBoxSettings` bound to `Style`:
  `borderWidth: Style.controlBorderWidth`, `borderColor: Style.accent`,
  `fillColor: Style.dark`.
- `control` (`QoolBoxShapeControl`): the octagon geometry unit. Default is a
  `QoolBoxShapeControl` with `target: root` and `settings: root.settings`. Both
  `settings` and `control` are publicly replaceable properties.
- `fillItem` (`Item`): any `Item` filled into the octagon's interior region (texture
  fill; when non-null it excludes the fallback path).
- `fillGradient` (`ShapeGradient`): the gradient fill channel. Default `null` (solid
  color); `fillItem` takes priority over the gradient. When non-null it excludes the
  fallback path — a `Rectangle` gradient and a `Shape` gradient are incompatible, so
  the fallback form keeps its "no fill channel" semantics. Note that
  `ShapePath::fillGradient` requires the new `ShapeGradient` API (`LinearGradient`
  and friends); the legacy `Gradient` type is not usable.
- `shape` (readonly, alias): the currently active rendering variant (the item loaded
  by the internal `Loader`).
- `animatingHint` (`bool`): animation hint. When `true`, the fallback judgment is
  skipped (keeping `Shape` rendering). Default `false`.
- `topSpace` / `bottomSpace` / `leftSpace` / `rightSpace` (readonly, `real`):
  forward `control`'s content-inset layout quantities, used by a host for layout
  padding. Formula `max(0, max(adjacent cut) − (used − expected)/2)`.

### settings and control replacement

Both are QObject references: replacing a `settings` instance (for example
`qbox.settings: otherBox.settings`) re-attaches the binding chain automatically
(whole-set assignment shares the instance; an independent copy means assigning a new
instance). Replacing or sharing a `control` (injecting a custom compatible type)
requires the same geometry source — matching sizes or setting `target` yourself; a
`control`'s `target` is unique and defaults to the `QoolBox` that created it.

### Fallback (performance mode)

When `curved` is `true`, the settings' four corner cuts satisfy the judgment (all `≤`
half the short edge, or all `0`), `fillItem` and `fillGradient` are both empty, and
`animatingHint` is `false`, the component falls back to a native rounded `Rectangle`
(the `cut*` values as corner radii, `offset` as `x`/`y`) — non-`Shape` rendering, so
the best performance. With `animatingHint` `true` (during animation) the fallback
judgment is skipped, keeping `Shape` rendering.

## Signals

This type defines no additional signals. (It inherits the standard `Item` signals.)

## Methods

This type defines no additional methods.

## Hit testing

The `containmentMask` delegates to the current variant: the straight-corner variant
uses `control`'s O(1) linear inequality (corner cuts do not hit); the rounded variant
uses path-fill judgment; the fallback rectangle uses rectangle judgment.

## Usage Example

```qml
import QtQuick
import Qool

QoolBox {
    width: 240
    height: 140
    settings: QoolBoxSettings {
        cutSizeTL: 20
        cutSizeTR: 20
        cutSizeBL: 20
        cutSizeBR: 20
        borderWidth: 2
        borderColor: "white"
        fillColor: "#20242b"
        curved: true
    }

    // Content laid out inside the octagon, padded by the inset quantities.
    Text {
        anchors.centerIn: parent
        text: "QoolBox"
        color: "white"
    }
}
```
