# MsgChannelSet

A channel-set value type: an unordered set of channels (`MsgChannel`).
Referred to as `msgchannelset` in QML.

`MsgChannelSet` (spelled `msgchannelset` in QML) expresses a set of
channels. It is a value-type wrapper around `QSet<MsgChannel>` and supports
set operations directly. The special channel `ALL` is a wildcard: a message
or beeper whose channel set contains `ALL` matches every channel (see the
`ChatRoomServer` message filtering).

## Properties

This type defines no properties. It behaves as a set of channels; the
QML-side operations are exposed through its methods.

## Signals

This type defines no additional signals.

## Methods

- `msgchannelset()` , `msgchannelset(list)`
  Constructs an empty set, or a set from a list of channels, a
  `QStringList`, a byte-array list, or a single channel string (which is
  decoded).

- `bool contains(string channel)`
  For a separator-delimited code string, the AND-semantics check: the string
  is decoded and every resulting channel must be present for the result to
  be `true`. For a single `QByteArray` channel it is a plain set-membership
  check.

- `bool contains(QByteArray channel)`
  Plain set-membership check for a single byte-array channel.

- `string[] toStringList()`
  Returns the channels as a sorted `QStringList`.

- `string encode()`
  Joins the sorted channel list with the separator character, producing the
  encoded string form.

- `static msgchannelset decode(string code)`
  Splits `code` on space, comma or semicolon and returns the resulting set.

## Usage Example

```qml
import QtQuick
import Qool.Chat

// Construction from an encoded string
var set = msgchannelset("lobby,general")

// Filtering semantics
if (set.contains("lobby,general")) {
    // true: both channels present (AND semantics)
}
if (set.contains("lobby")) {
    // true: plain membership
}
```
