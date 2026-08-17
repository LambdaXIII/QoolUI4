# FileInfoHQ

The QML-facing file-metadata singleton: file info queries hitting an App-level shared cache.

`FileInfoHQ` is a QML singleton with **one independent instance per `QQmlEngine`** (created via `create()`, parented to the engine). Multi-engine scenarios (QML test framework, multi-window/multi-view hosts) give each engine its own object; the objects are not shared. The file-info data itself is App-level shared: the underlying `FileInfoDB` (a process-level C++ global singleton) caches general file information keyed by `QUrl` (name, path, size, timestamps, type flags — see the returned fields below) plus plugin-supplemented information from `FileInfoProvider` plugins ordered by priority. `getFileInfo()` from any engine hits the same cache.

### Cache and invalidation

The cache holds up to 2000 entries, auto-evicted by `QCache`. On a hit, the disk file's `lastModified` timestamp is compared with the cached value; a modified file regenerates its cache entry, so the returned information is always fresh. `getFileInfo()` returns a copy of the value, safe to call repeatedly.

### Single-thread contract

Cache queries/writes are confined to the main thread — the caller (the QML engine) satisfies this naturally; cross-thread access is forwarded through Qt's `AutoConnection` queued delivery. Without plugins, only the generic fields below are returned.

Returned fields: `originalInput`, `lastModified`, `lastRead`, `birthTime`, `fileName`, `filePath`, `baseName`, `absoluteFilePath`, `absolutePath`, `completeBaseName`, `completeSuffix`, `suffix`, `isDir`, `isFile`, `isHidden`, `isReadable`, `isShortcut`, `isSymLink`, `isSymbolicLink`, `isWritable`, `exists`, `symLinkTarget`, `readSymLink`, `isBundle`, `bundleName`, `size`, `url`, `iconUrl`.

## Properties

This type defines no properties.

## Signals

This type defines no signals.

## Methods

- `QVariantMap getFileInfo(QUrl fileUrl)`
  Returns the cached info for the URL, regenerating the cache entry when the file changed.

- `QVariantMap getFileInfo(QString filePath)`
  Convenience overload for a local path (converted with `QUrl::fromLocalFile`).

## Usage Example

```qml
import QtQuick
import Qool.File

// FileInfoHQ is a singleton; every engine gets its own instance,
// all sharing the same underlying cache.
property var info: FileInfoHQ.getFileInfo("C:/path/to/file.txt")

// info.size, info.lastModified, info.isDir, info.exists, info.iconUrl, ...
```
