# ColorNameList

A color name list: category switching plus a clickable list of color names
linked to a `ColorAssistant`.

`ColorNameList` is a `ColumnLayout` composing, top to bottom:

1. A `CycleChoice` category switcher whose options are the plugin
   categories returned by `ColorNameHQ.categories()` (e.g. the default
   plugin's `"DEFAULT"`); each click cycles to the next category and
   `displayText` shows the current one.
2. A `ColorNameView` color name list showing all names of the current
   category; clicking a name updates `colorAssistant`.

### Selection linkage

- Clicking a name in the list changes `currentColor`, which writes
  `colorAssistant.color`.
- If `colorAssistant.color` is changed externally (and differs from the
  currently selected name's color), the list selection is cleared
  (`deselect`) — external synchronization and list selection are mutually
  exclusive, so the selection never disagrees with the external color.

### Category switching

Category data comes from `ColorNameHQ.categories()` (the union of
categories declared by the installed plugins). This component does not
bundle category data — the full set of categories is determined by the
installed plugins.

### Defaults and size

The default `colorAssistant` comes pre-configured with `Style.highlight`,
so standalone use works without injection. The default size is
`implicitHeight: 500` / `implicitWidth: 200`; the host may override these
or place the component in a layout controlled by `Layout.fill*`.

## Properties

- `colorAssistant : ColorAssistant` (default: own instance with `color:
  Style.highlight`)
  The color data source. List clicks write to this property; external
  writes to it clear the list selection (see above).

- `animationEnabled : bool` (default: inherited from the parent, falling
  back to `Style.animationEnabled`)
  The animation master switch; forwarded to the internal `CycleChoice` and
  `ColorNameView`.

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Color

ColorAssistant {
    id: shared
    color: Style.highlight
}

ColorNameList {
    colorAssistant: shared
    Layout.fillWidth: true
    Layout.fillHeight: true
}
```
