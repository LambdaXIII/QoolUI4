# FileInfoListModel

A `QAbstractListModel` whose data items are `fileinfo` values — the data source of the file-list views.

`FileInfoListModel` holds a `FileInfoList` (an internal list by default, replaceable wholesale through the `fileInfos` property). Public roles: `fileInfo` (the `fileinfo` object), `absoluteFilePath`, `url`, `isFile`, `isDir`, `displayName`, `fileName`, `baseName`, `suffix`, `exists`, `size`, `birthTime`, `lastModified`, `icon`.

### Single-thread contract

All API must be called on the owning thread (the main thread by default). Earlier versions wrapped every operation in a `QRecursiveMutex`, but no cross-thread caller ever existed — the lock was dead code and violated Qt model-threading conventions (`QAbstractItemModel` is not thread-safe; the official contract is to forward cross-thread access through queued signals/connections and let the receiving thread own the model). If cross-thread access is ever needed, forward to the model thread instead of re-introducing a lock.

### Index and bounds defense

High-frequency query entries such as `data()` return an empty value for illegal row numbers instead of going out of bounds — some view implementations do pass illegal rows to `data()`, where `at(row)` would be UB. `removeAt()`/`takeAt()` warn and ignore out-of-range indexes; `removeRange()` constrains its range by assertion. Batch operations first filter invalid/duplicate indexes (`validateIndexes`), sort and deduplicate, then fix positions with `QPersistentModelIndex`, so index drift during multiple removals cannot delete the wrong elements.

### move semantics

`move(from, to)` follows the `beginMoveRows` `destinationChild` "insertion point before the destination row" semantics: moving down, the final landing position is `to - 1`, so internally `to + 1` is passed (Qt's `QList::move` landing already includes this off-by-one); moving up passes `to` unchanged. `move(rows, to)` (batch) first removes all selected rows (persisted indexes), then re-inserts the whole group at the destination row; `to` equal to the list length means "move to the end" (`index(to)` is invalid then — the destination row becomes the post-removal list length, appending).

### Batch-operation contract

The batch `insert`/`append` overloads return directly on empty lists, avoiding the illegal `beginInsertRows(first > last)` call. Removal-type operations emit `fileInfosRemoved` uniformly after `endRemoveRows`. Sort/deduplicate-type operations (`sortInfos`, `clear`, `forceResetInfos`) perform a full reset via `beginResetModel`/`endResetModel`, and `fileInfosRemoved` must be delayed until after `endResetModel` — during a reset the view is in an intermediate state, and emitting with stale data would violate the model/view signal contract.

## Properties

- `fileInfos`
  The `FileInfoList` backing the model. Internal by default; assigning an external list replaces the whole content (model reset, `fileInfosChanged` emitted).

## Signals

- `fileInfosInserted(QList<qsizetype> indexes)`
  Emitted after rows were inserted, with the inserted row indexes.

- `fileInfosRemoved(FileInfoList infos)`
  Emitted after rows were removed — always after `endRemoveRows` (or after `endResetModel` for reset-type operations), never during a reset.

## Methods

- `qsizetype indexOf(fileinfo info)`
  Returns the first row index of `info`, or -1.

- `void insert(qsizetype index, fileinfo info)`
  Inserts one item at `index` (clamped to `[0, length]`).

- `void insert(qsizetype index, list<fileinfo> infos)`
  Inserts a batch at `index`; returns directly when the batch is empty.

- `void append(fileinfo info)` / `void append(list<fileinfo> infos)`
  Appends one item or a batch at the end.

- `void removeAt(qsizetype index)`
  Removes one row; out-of-range indexes are warned and ignored.

- `void removeRange(qsizetype first, qsizetype last)`
  Removes the inclusive range (asserts validity).

- `void remove(list<qsizetype> indexes)`
  Removes the given rows (equivalent to `take()`); duplicates and invalid indexes are filtered.

- `fileinfo takeAt(qsizetype index)`
  Removes and returns one row; out-of-range indexes are warned and ignored.

- `list<fileinfo> take(list<qsizetype> indexes)`
  Removes and returns the given rows, persist-index-safe.

- `qsizetype move(qsizetype from, qsizetype to)`
  Moves one row (see the move-semantics notes above).

- `list<qsizetype> move(list<qsizetype> rows, qsizetype to)`
  Moves the given rows as a group; returns their new row indexes.

- `fileinfo infoAt(qsizetype index)`
  Returns the item at `index` (clamped to the last row).

- `list<fileinfo> infos(list<qsizetype> indexes = [])`
  Returns the items at the given rows (empty list = all rows). This is the model query used by the view layer — note it is `infos()`, not `getFileInfos()`.

- `list<QUrl> urls(list<qsizetype> indexes = [])`
  Returns the URLs of the given rows (empty list = all rows).

- `void sortInfos(bool removeDups = true)`
  Sorts by absolute path (directories first, stable), optionally removing adjacent duplicates.

- `void removeDirs()` / `void removeFiles()`
  Removes all directory rows / file rows.

- `void removeDuplicates()`
  Removes duplicate entries, keeping the first occurrence of each.

- `bool isEmpty()`
  Returns whether the model has no rows.

- `void clear()`
  Removes all rows.

- `void forceResetInfos(list<fileinfo> infos)`
  Replaces the whole content (no-op when the content is unchanged).

## Usage Example

```qml
import QtQuick
import Qool.File

FileInfoListModel {
    id: filesModel
}

ListView {
    anchors.fill: parent
    model: filesModel
    delegate: Text {
        text: model.displayName
    }
}

// Application code:
// filesModel.append(url)  — wrap a local path in a fileinfo first
// filesModel.sortInfos(true)
// filesModel.move(2, 0)
```
