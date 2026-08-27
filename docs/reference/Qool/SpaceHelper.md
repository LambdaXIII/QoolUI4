# SpaceHelper

A layout-space computation helper. `SpaceHelper` holds an outer size
(`width` / `height`) together with three independent sets of edge offsets —
*paddings*, *insets* and *margins* — and derives, as automatically updated
read-only properties, the sizes and rects of the three nested regions they
define.

The regions form a three-layer stack expressed in the object's own
coordinate system (origin at the top-left corner of `rect`):

- **`rect`** — the object's box: `(0, 0, width, height)`.
- **`backgroundRect`** — `rect` shrunk inward by the *insets*: the region
  the background is drawn in.
- **`contentRect`** — `rect` shrunk inward by the *paddings*: the region
  the content is placed in.
- **`marginRect`** — `rect` expanded outward by the *margins*: its origin
  lies at `(-leftMargin, -topMargin)`.

Each region's derived width/height and rect recompute automatically
whenever any input changes, and notify only when the resulting value
actually changes.

`SpaceHelper` inherits `SmartObject` and is registered as a QML type in
the `Qool` module (`import Qool`), usable from QML and C++ alike.

All properties are *bindable* properties (`QBindable`): the QML engine
tracks and updates them through the bindable interface, so regular QML
bindings (`width: parent.width`) behave as expected.

## Properties

Every property below has an auto-generated, value-guarded `xxxChanged`
signal that fires only when the property's actual value changes.

### Sizing

- `width : real` (read/write, default `100`)
  The outer width of the object — the base of all derived sizes.

- `height : real` (read/write, default `100`)
  The outer height of the object.

### Paddings (content inset)

- `topPadding`, `bottomPadding`, `leftPadding`, `rightPadding : real`
  (read/write, default `0`)
  Edge offsets that shrink `rect` into `contentRect`. They are
  independent: changing one side does not affect the others.

- `padding : real` (read/write, default `0`)
  Bulk write for the four paddings: assigning a value sets all four side
  paddings to it at once, as one atomic update group.
  `padding` is a *mirror of the last bulk write*, not a derived value: it
  is **not** updated when individual sides are changed afterwards, so
  reading it can report a value that no longer matches the sides.

### Insets (background inset)

- `topInset`, `bottomInset`, `leftInset`, `rightInset : real`
  (read/write, default `0`)
  Edge offsets that shrink `rect` into `backgroundRect`.

- `inset : real` (read/write, default `0`)
  Bulk write for the four insets; same mirror semantics as `padding`.

### Margins (outer spacing)

- `topMargin`, `bottomMargin`, `leftMargin`, `rightMargin : real`
  (read/write, default `0`)
  Edge offsets that expand `rect` outward into `marginRect`.

- `margin : real` (read/write, default `0`)
  Bulk write for the four margins; same mirror semantics as `padding`.

### Derived regions (read-only)

- `contentWidth : real`
  `width - leftPadding - rightPadding`.

- `contentHeight : real`
  `height - topPadding - bottomPadding`.

- `backgroundWidth : real`
  `width - leftInset - rightInset`.

- `backgroundHeight : real`
  `height - topInset - bottomInset`.

- `marginWidth : real`
  `width + leftMargin + rightMargin`.

- `marginHeight : real`
  `height + topMargin + bottomMargin`.

- `rect : rect`
  The object's box: `(0, 0, width, height)`.

- `contentRect : rect`
  `(leftPadding, topPadding, contentWidth, contentHeight)`.

- `backgroundRect : rect`
  `(leftInset, topInset, backgroundWidth, backgroundHeight)`.

- `marginRect : rect`
  `(-leftMargin, -topMargin, marginWidth, marginHeight)`.

Derived properties are read-only and cannot be assigned from QML or C++.
Their values are maintained by internal bindings established at
construction.

**Offsets are not validated.** Negative values are accepted and flow into
the arithmetic: a negative padding yields a content region larger than the
box, offsets larger than the box size invert a region, and so on. There is
no clamping and no error reporting — such configurations show up
immediately in the derived values.

## Signals

Every property has an auto-generated `xxxChanged()` signal (e.g.
`widthChanged`, `topPaddingChanged`, `contentRectChanged`). Signals are
value-guarded: they fire only when the property's actual value changes.
Derived properties fire when their recomputed value differs from the
previous one.

Signals inherited from `SmartObject` (`parentChanged()`,
`itemAppended(child)`) are also available.

## Methods

- `setPaddings(top : real, right : real, bottom : real, left : real)`
  Sets all four paddings at once. The four writes are committed as a
  single atomic update group: change notifications are delivered together
  when the call completes, so observers never see an intermediate mix of
  old and new side values. The aggregate `padding` is **not** modified.

- `setInsets(top : real, right : real, bottom : real, left : real)`
  Same behavior as `setPaddings`, for the four insets.

- `setMargins(top : real, right : real, bottom : real, left : real)`
  Same behavior as `setPaddings`, for the four margins.

All three methods take the arguments in the order `top, right, bottom,
left` (CSS-style). They are `Q_INVOKABLE` and callable from QML.

`dumpProperties()` is inherited from `SmartObject`.

## Usage Example

```qml
import QtQuick
import Qool

Item {
    id: root
    width: 200
    height: 120

    SpaceHelper {
        id: space
        width: root.width
        height: root.height
        padding: 12    // all four paddings at once
        inset: 4
        margin: 8
    }

    // Background fills backgroundRect (rect shrunk by the insets).
    Rectangle {
        x: space.backgroundRect.x
        y: space.backgroundRect.y
        width: space.backgroundRect.width
        height: space.backgroundRect.height
        color: "#e6e6e6"
    }

    // Content is placed inside contentRect (rect shrunk by the paddings).
    Text {
        x: space.contentRect.x
        y: space.contentRect.y
        width: space.contentRect.width
        height: space.contentRect.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "Content"
    }
}
```
