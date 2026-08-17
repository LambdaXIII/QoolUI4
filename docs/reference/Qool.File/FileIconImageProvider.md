# FileIconImageProvider

Provides filesystem icons (pixmaps) under the `image://qoolfileicon` protocol.

`FileIconImageProvider` is a `QQuickImageProvider` registered by the Qool.File plugin. `schema()` returns the protocol name `qoolfileicon`; after registration, `image://qoolfileicon/<encoded file path>` resolves to the icon of that file.

`requestPixmap()` hands the id to `FileIconDB`, which routes to the concrete provider that can supply the icon (high priority first). If a requested size is given, the icon is scaled with `KeepAspectRatio` + `SmoothTransformation`; otherwise the default 64×64 pixmap is produced. When the path is invalid, a white placeholder pixmap is returned.

The provider is constructed with `ForceAsynchronousImageLoading`, so icon decoding never blocks the render thread.

## Percent escaping

`compileUrl()` percent-encodes the file path via `QUrl::toPercentEncoding` before concatenating it into the URL. This is required because a `%` in the path would otherwise be interpreted by `QUrl` as a percent-escape sequence: when it happens to form valid hex, the path is corrupted (`"50%20off.png"` becomes `"50 off.png"`); when invalid, parsing fails. On the provider side the id is decoded back automatically via `QUrl::path()`, so no manual `fromPercentEncoding` is needed.

## Properties

This type defines no properties.

## Signals

This type defines no signals.

## Methods

- `QString schema()` (static)
  Returns the protocol name: `qoolfileicon`.

- `QUrl compileUrl(QAnyStringView filePath)` (static)
  Compiles a file path into a percent-escaped `image://qoolfileicon` URL.

- `QPixmap requestPixmap(QString id, QSize* size, QSize requestedSize)`
  (C++ override) Resolves `id` to a pixmap through `FileIconDB`, scaled to `requestedSize` when valid. Not called from QML directly.

## Usage Example

Application code never instantiates this type; the module plugin registers it, and the `image://qoolfileicon` URLs produced by `FileIconHQ.iconUrl()` (or `compileUrl()`) are loaded by any image element:

```qml
import QtQuick
import Qool.File

Image {
    source: FileIconHQ.iconUrl("C:/path/to/archive.zip")
}
```
