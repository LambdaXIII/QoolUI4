# FileInfoListView

A multi-select file list view specialized for `FileInfoListModel` — the View layer of the multi-layer plug-in chain (View → Delegate → Display).

`FileInfoListView` pairs a `FileInfoListModel` with a built-in `MultiRowSelectionModel` and offers ready-made list operations: selection toggling, sorting, deduplication, removal and clearing. The default `delegate` is `FileInfoDelegate` (which can be replaced wholesale), and `fileInfoDisplay` is passed through to the delegate's display component (default `BasicFileInfoDisplay`), so the appearance can be replaced without losing delegate behavior.

The view itself accepts no mouse buttons (`acceptedButtons: Qt.NoButton`): all interaction is handled by the delegate. The default model is an empty `FileInfoListModel`; replace `model` to use your own instance.

Note: the model query method used by `selectedFileInfos()` is `FileInfoListModel.infos()` — a call to a non-existent `getFileInfos()` would fail silently.

## Properties

- `fileInfoDisplay : Component` (default `BasicFileInfoDisplay {}`)
  The display component passed to each delegate row.

- `selectionModel : MultiRowSelectionModel`
  The selection model; defaults to an instance bound to `root.model`.

- `containsSelection : bool` (readonly)
  `true` while at least one row is selected.

- `fileInfoListModel : FileInfoListModel` (readonly)
  Alias of `model`; the underlying list model.

Inherited from `ListView`: `model` (default `FileInfoListModel {}`), `delegate` (default `FileInfoDelegate` wired to the properties above), `cacheBuffer` (400), `boundsBehavior` (`Flickable.DragOverBounds`), and all other `ListView`/`Flickable`/`Item` properties. See the Qt documentation for the inherited members.

## Signals

This type defines no additional signals (inherits all signals from `ListView`).

## Methods

- `void selectAll()`
  Selects all rows (equivalent to `selectionModel.selectAll()`).

- `void toggleAll()`
  Inverts the selection of all rows.

- `void clearSelection()`
  Clears the current selection.

- `list<int> selectedRows()`
  Returns the row indexes of the current selection.

- `list<fileinfo> selectedFileInfos()`
  Returns the `fileinfo` objects of the selected rows, queried via `fileInfoListModel.infos(rows)`.

- `void clear()`
  Clears the model data (equivalent to `fileInfoListModel.clear()`).

- `void removeRows(list<int> rows)`
  Removes the rows by index list (equivalent to `fileInfoListModel.remove(rows)`).

- `void sortFileInfos()`
  Sorts by path without deduplication (`fileInfoListModel.sortInfos(false)`).

- `void arrangeFileInfos()`
  Sorts by path and removes duplicates (`fileInfoListModel.sortInfos(true)`).

- `void removeDuplicates()`
  Removes duplicate entries from the list.

## Usage Example

```qml
import QtQuick
import Qool.File

FileInfoListView {
    id: view
    anchors.fill: parent
    // model defaults to an empty FileInfoListModel
}

// Application code — feed the model through the model layer (e.g. from a
// FileDropper drop handler), then drive the built-in list operations:
view.arrangeFileInfos()          // sort + deduplicate
view.selectAll()                 // select every row
view.selectedFileInfos()         // → list<fileinfo>
view.removeDuplicates()
```
