# Style

The style attached property of the `Qool` module: the QML-side entry point of
the theme system. It provides 60+ typed style properties (colors, sizes,
durations, cut sizes, spacings) grouped into three state groups
(`Active` / `Inactive` / `Disabled`), propagated down the item hierarchy and
backed by a named `Theme` from the theme database.

`Style` is a C++ attached type (`QQuickAttachedPropertyPropagator` subclass,
declared `QML_ATTACHED`, `QML_UNCREATABLE`). It is used as an attached
property on any object — `Style.theme: "midnight"` on a root item or
`Style.accent: "#ff8800"` on a single control. Attached properties propagate
through items, popups and windows, mirroring Qt's font/palette propagation;
each host item sees the *effective* style of its position in the hierarchy.

## Design

Three layers cooperate:

1. **Grouped data.** Each `Style` instance holds three resolved value maps
   (`m_activeData` / `m_inactiveData` / `m_disabledData`) plus per-group
   modified marks. The *current group* is derived from the host item's state
   through `ItemTracker` bindables: item disabled → `Disabled`; window
   inactive → `Inactive`; otherwise `Active`. A group switch re-emits every
   typed property signal so bindings re-read the new group's values.
2. **Typed properties.** Reading a property (`Style.accent`) returns
   `get_value(currentGroup, "accent")`. Writing one (`Style.accent = x`)
   writes **all three groups** and marks all of them modified — a host
   override survives later theme changes and parent inheritance. This
   non-const write face is the host injection contract; see
   [Style 体系](../../articles/style-system.md).
3. **Theme binding.** `theme` names a `Theme` installed in the `ThemeDB`.
   Changing it re-resolves the group maps from the database (skipping
   modified keys) and propagates the new values down the attached tree.

Inheritance: on construction (`initialize()`) and on
`attachedParentChange`, a `Style` inherits its attached parent's theme name
and group data, copying **resolved** values (not theme keys) and skipping
keys the host modified. A subtree therefore never re-queries the database
unless its own `theme` property changes.

**Theme boundary (design contract).** Setting `theme` on an item makes it a
*theme source*: the item and its subtree use that theme, and ancestor theme
changes must not propagate through it — same intent as the per-value
override, but scoped to the whole region. Setting `theme` marks the item
explicit (`m_explicitTheme`); an explicit node refuses `inherit`, so
ancestor theme changes stop at the boundary. An explicit node has no
"revert to inherited" path (same as the per-value override — re-set a
concrete theme to change the source). See
[Style 体系](../../articles/style-system.md) (contract C3).

`animationEnabled` is a plain member (default `true`), **not** group data:
setting it only propagates down the attached tree. `follow` live-copies
another `Style`'s values unless a key is locally modified. `active` /
`inactive` / `disabled` expose group-scoped read/write faces
(`StyleGroupAgent`) with the same typed properties.

## Properties

- `theme : string` (default `"system"`)
  The theme name resolved from the `ThemeDB`. Unknown names fall back to the
  first installed theme. Changing it re-applies every non-modified value for
  all three groups and propagates to attached children.

- `animationEnabled : bool` (default `true`)
  The "high-performance vs. full effect" switch. Not part of the group data:
  a plain member whose value flows **down** the attached tree (children are
  overwritten; there is no fallback to theme constants). Set it on an
  ancestor to gate animation/heavy effects for a whole subtree.

- `follow : Style`
  Another `Style` whose values are live-copied into this instance unless a
  key was locally modified. Used e.g. by popup delegates to follow their
  owning control's style.

- `active : StyleGroupAgent` (constant, read-only reference)
  Group-scoped face for the `Active` group; see the table below for its
  properties.

- `inactive : StyleGroupAgent` (constant, read-only reference)
  Group-scoped face for the `Inactive` group.

- `disabled : StyleGroupAgent` (constant, read-only reference)
  Group-scoped face for the `Disabled` group.

- Color properties (`color`): `white`, `silver`, `grey`, `black`, `red`,
  `maroon`, `yellow`, `olive`, `lime`, `green`, `aqua`, `cyan`, `teal`,
  `blue`, `navy`, `fuchsia`, `purple`, `orange`, `brown`, `pink`,
  `positive`, `negative`, `warning`, `controlBackgroundColor`,
  `controlBorderColor`, `infoColor`, `accent`, `light`, `midlight`, `dark`,
  `mid`, `shadow`, `highlight`, `highlightedText`, `link`, `linkVisited`,
  `text`, `base`, `alternateBase`, `window`, `windowText`, `button`,
  `buttonText`, `placeholderText`, `toolTipBase`, `toolTipText`.

- Size properties (`int`): `textSize`, `titleTextSize`, `toolTipTextSize`,
  `importantTextSize`, `decorativeTextSize`, `controlTitleTextSize`,
  `controlTextSize`, `windowTitleTextSize`.

- Duration properties (`real`): `instantDuration` (100), `transitionDuration`
  (200), `movementDuration` (400).

- Cut-size properties (`real`): `menuCutSize`, `buttonCutSize`,
  `controlCutSize`, `windowCutSize`, `dialogCutSize`.

- Border-width properties (`real`): `controlBorderWidth`,
  `windowBorderWidth`, `dialogBorderWidth`.

- Spacing properties (`real`): `windowElementSpacing`, `windowEdgeSpacing`.

- `papaWords : stringList`
  Decorative words (used by `PaPaWall`-family covers).

> **Read/write asymmetry.** Reading a typed property returns the value of
> the *current* group (derived from the host state). Writing assigns to
> **all three** groups and marks them modified, so the value applies in
> every state and survives theme changes. To override a single group only,
> write through the group face: `Style.inactive.accent = "..."` writes the
> `Inactive` group alone.

> **Data gaps.** The `system` theme (derived from the system palette) does
> not define `infoColor` — reading it under `theme: "system"` yields an
> invalid color. `brightText` does not exist on `Style` or the group faces
> (see `QoolPalette`).

## Signals

- `valueChanged(int group, string key)`
  Emitted whenever a group map changes (typed-property writes, group-face
  writes, inheritance, theme re-resolution, follow). Internal wiring
  consumes it; typed `xxxChanged` signals for the current group follow.

- `themeChanged()`
  Emitted when the `theme` property changes.

- `animationEnabledChanged()`
  Emitted after the value changed and was propagated down the attached tree.

- `followChanged()`
  Emitted when the `follow` target changes.

- `xxxChanged()` for every typed property listed above. Emitted when the
  property's value in the *current* group changes, or when the current group
  switches (all properties re-notify so bindings re-read the new group).

## Methods

- `get_value(group : int, key : string, defvalue : variant = {}) : variant`
  (C++ only, not `Q_INVOKABLE`)
  Returns the raw value of `key` in `group`, or `defvalue` if absent.

- `set_value(group : int, key : string, value : variant) : bool`
  (C++ only)
  Writes `value` into `group`; returns `false` if the value was unchanged.
  Emits `valueChanged(group, key)` on change.

- `mark_modified(group : int, key : string)` / `is_modified(group : int,
  key : string) : bool` (C++ only)
  Tracks whether a key was explicitly overridden by the host. Modified keys
  are skipped by inheritance and theme re-resolution.

- `dumpInfo()`
  Debug dump: theme, tracking item/window, attached parent chain, attached
  children, properties and modified keys, and a warning when all three
  groups are equal.

- `dumpAllChildren()`
  Debug dump of the attached children (current implementation lists direct
  children only).

## Usage Example

```qml
import QtQuick
import QtQuick.Controls
import Qool

// Root: inject a theme. Applies to the whole window subtree.
ApplicationWindow {
    Style.theme: "midnight"

    // Disable heavy effects for the entire subtree.
    Style.animationEnabled: false

    Button {
        // Host override — written to all three groups, never overwritten
        // by theme changes or parent inheritance.
        Style.accent: "#ff8800"

        // Read the style (current group selected by host state).
        text: qsTr("Accent is %1").arg(Style.accent)
    }
}

// Group-scoped read / write.
Text {
    // Read the Active group explicitly (regardless of window state).
    color: Style.active.accent

    // Write a single group only.
    // Style.disabled.text = "grey"
}

// Live-follow another style: popup delegates follow their owner.
ComboBox {
    id: combo
    delegate: ItemDelegate {
        Style.follow: combo.Style
    }
}
```

For theme authoring (XML format, install), see `ThemeHQ`, `ThemeHQModel` and
the [Style 体系](../../articles/style-system.md) article.
