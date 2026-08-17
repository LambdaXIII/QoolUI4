# FileIconHQ

The QML-facing file-icon singleton: compiles a local file path into an icon URL.

`FileIconHQ` is a QML singleton with **one independent instance per `QQmlEngine`** (created via `create()`, parented to the engine). In multi-engine scenarios — the QML test framework creates a separate engine per test file, and multi-window/multi-view hosts may run several engines — each engine uses its own `FileIconHQ` object; instances are never shared.

The icon data itself is App-level shared: the underlying `FileIconDB` (a process-level C++ global singleton) owns the provider table (at construction it auto-installs every `FileIconProvider` plugin via `PluginLoader`, ordered by priority) and the routing for the `image://qoolfileicon` protocol. When no icon provider plugins are installed, no icon can be provided (a warning is emitted).

The class only carries the QML face; it delegates to `FileIconImageProvider::compileUrl` and does not touch `FileIconDB` state directly.

## Properties

This type defines no properties.

## Signals

This type defines no signals.

## Methods

- `QUrl iconUrl(QUrl fileUrl)`
  Compiles a local file path into an `image://qoolfileicon` protocol icon URL (equivalent to `FileIconImageProvider::compileUrl`), suitable for loading by `Image` and friends.

## Usage Example

```qml
import QtQuick
import Qool.File

Image {
    // FileIconHQ is a singleton; iconUrl returns an image://qoolfileicon URL.
    source: FileIconHQ.iconUrl("C:/path/to/report.pdf")
}
```

The `image://qoolfileicon` scheme is resolved by the `ImageProvider` that the module plugin registers — the host needs no extra registration.
