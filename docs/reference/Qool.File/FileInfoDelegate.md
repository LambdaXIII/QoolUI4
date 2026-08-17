# FileInfoDelegate

The default row delegate of `FileInfoListView` — the behavior layer of the multi-layer plug-in chain (View → Delegate → Display).

`FileInfoDelegate` carries all row behavior:

- **Multi-selection**: a click toggles the row; `Shift`+click performs a range select; `Ctrl`+click multi-selects. A 200 ms long-press also multi-selects the row and starts a drag.
- **Drag reorder**: while held, the row can be dragged along the Y axis to reorder; dropping on another row moves the dragged row (or the whole current selection, via `FileInfoListModel.move`).
- **Drop insertion**: external drags with URLs insert the URLs into the model at the drop position. The drop target is highlighted by an insertion indicator (top/bottom half split at 60%).

Behavior and style are separated: the display component is loaded through the `fileInfoDisplay` property (default `BasicFileInfoDisplay`) with the `checked`/`fileInfo` contract injected. Replacing only the display keeps all behaviors.

## Properties

- `fileInfo : fileinfo` (required)
  The file information for this row.

- `index : int` (required)
  The row index in the model.

- `selectionModel : MultiRowSelectionModel` (required)
  The shared selection model of the view.

- `fileInfoListModel : FileInfoListModel` (required)
  The underlying list model, used for move/insert operations.

- `fileInfoDisplay : Component` (default `BasicFileInfoDisplay {}`)
  The display component for this row. The delegate injects `checked` and `fileInfo` into its loaded instance.

- `checked : bool` (readonly)
  Whether this row is selected (mirrors `selectionModel.isRowSelected(index)`).

Inherited from `Control` (`QtQuick.Controls`): all `Control` properties. See the Qt documentation for the inherited members.

## Signals

This type defines no additional signals (inherits all signals from `Control`).

## Methods

This type defines no additional methods (inherits all methods from `Control`).

## Usage Example

The delegate is wired up automatically by `FileInfoListView`. It can also be used in a plain `ListView` when the required properties are supplied:

```qml
import QtQuick
import QtQuick.Controls
import Qool.File

ListView {
    model: filesModel
    delegate: FileInfoDelegate {
        fileInfo: model.fileInfo
        selectionModel: filesSelectionModel
        fileInfoListModel: filesModel
    }
}
```

To customize the row appearance, replace the display component instead of the whole delegate:

```qml
FileInfoListView {
    fileInfoDisplay: Component {
        // any component implementing `checked: bool` + `fileInfo: fileinfo`
        MyRowDisplay {}
    }
}
```
