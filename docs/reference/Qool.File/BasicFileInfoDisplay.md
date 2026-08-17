# BasicFileInfoDisplay

The default display component of `FileInfoDelegate` — the Display layer of the `FileInfoListView` multi-layer plug-in chain (View → Delegate → Display).

`BasicFileInfoDisplay` is a pure style component: icon + file name + selected/hover background, all sourced from the `Style` system. It has no behavior of its own; row behavior (multi-select, drag reorder, drop insertion) lives in the Delegate layer. It is loaded by the delegate through a `Loader` and injected with the contract properties `checked` and `fileInfo`.

Styling rules:

- Text color: invalid `fileInfo` → `Style.negative`; checked → `Style.highlightedText`; hovered → `Style.highlight`; otherwise `Style.text`.
- Background: invalid `fileInfo` → `Qt.alpha(Style.negative, 0.08)`; checked → `Style.highlight`; otherwise transparent.
- The label shows `fileInfo.fileName`, or "无效文件" (qsTr) when the info is invalid.

Color transitions use `BasicColorBehavior`.

## Properties

- `fileInfo : fileinfo`
  The file information to display. When invalid (e.g. a path that does not exist), the row shows the invalid-file styling described above.

- `checked : bool` (default `false`)
  The selected state of the row, injected by `FileInfoDelegate`.

Inherited from `Control` (`QtQuick.Controls`): `hoverEnabled` (set to `true`), `padding` (default 2), `contentItem`, `background`, and all other `Control` properties. See the Qt documentation for the inherited members.

## Signals

This type defines no additional signals (inherits all signals from `Control`).

## Methods

This type defines no additional methods (inherits all methods from `Control`).

## Usage Example

`BasicFileInfoDisplay` is not meant to be instantiated standalone: the delegate loads it and injects `checked`/`fileInfo`. To replace the appearance without losing delegate behavior, supply a custom display component with the same contract properties through `FileInfoListView.fileInfoDisplay` (or `FileInfoDelegate.fileInfoDisplay`):

```qml
import QtQuick
import Qool
import Qool.Controls.Components
import Qool.File

Component {
    id: compactDisplay

    // Custom display contract: must implement `checked` and `fileInfo`.
    Control {
        property fileinfo fileInfo
        property bool checked: false

        padding: 2
        contentItem: Text {
            text: fileInfo.fileName
            color: checked ? Style.highlightedText : Style.text
        }
    }
}

FileInfoListView {
    anchors.fill: parent
    fileInfoDisplay: compactDisplay
}
```
