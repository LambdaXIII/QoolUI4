# Message

A message value type carrying text content, attachments, target channels and
sender identity (timestamp and ID). Referred to as `qoolmessage` in QML.

`Message` (spelled `qoolmessage` in QML) holds a chat message: the `content`
text, an `attachments` key/value table, the target `channels`, the `senderID`,
plus system-generated `created` / `messageID` identity fields. It can be
constructed in QML from an object literal
(`QML_CONSTRUCTIBLE_VALUE`).

## Properties

- `content : string` (read/write)
  The message text body.

- `attachments : var` (read/write)
  A key/value attachment table (a `QVariantMap`). Arbitrary named values can
  be attached and later queried via `attachment()` / `contains()`.

- `channels : MsgChannelSet` (read/write, notifies `channelsChanged`)
  The target channel set of the message.

- `channel : string` (read/write, notifies `channelsChanged`)
  A convenience decodable-string form of `channels`. Writing a value decodes
  it into the underlying `channels` set.

- `senderID : QByteArray` (read/write)
  The sender identity. Filled in automatically by `Beeper::postMessage`
  with the sending beeper's own `name`.

- `created : datetime` (read-only)
  The system-generated creation time. See "Copy identity" below.

- `messageID : QByteArray` (read-only)
  The system-generated unique message ID. See "Copy identity" below.

## Copy identity (deliberate design)

Copy construction produces a brand-new `created` and `messageID`. A copied
`Message` is a new message with the same content but a different identity
(identity = send time + message ID). `operator==` compares `messageID`, so a
copy is never equal to its source. Scenarios that need a shared-identity
shallow copy (such as forwarding/re-sending) follow the same path, with the
semantics "same content, different identity". Do not treat this as a bug.

## Signals

This type defines no additional signals.

## Methods

All mutating methods below return the same `Message` instance and can be
chained.

- `Message()` , `Message(string content)` , `Message(object { … })`
  Constructs an empty message, a message with the given `content`, or a
  message from an object literal. Object-literal construction recognizes the
  keys `content`, `channels` / `channel` and `senderID`; the reserved keys
  `created`, `messageID`, `attachment` and `attachments` are rejected with a
  warning; any other key becomes an attachment (a null value removes that
  attachment key).

- `bool contains(string key)`
  The AND-semantics full-containment check: when `key` is a
  comma-separated list, every item must be present in the attachments.
  Empty string / empty set is a wildcard (always `true`). Intended for
  channel/attachment filtering — do not interpret it as "substring
  contains".

- `variant attachment(string key)`
  Returns the attachment value for `key`, or an invalid variant if absent.

- `Message attach(string key, variant value)`
  Attaches `value` under `key` (a null `value` removes that key). Chainable.

- `Message addChannel(string channel)`
  Adds the decoded channel(s) to the message. Chainable.

- `Message addChannels(MsgChannelSet channels)`
  Unites `channels` into the message's channel set. Chainable.

- `Message removeChannel(string channel)`
  Removes the decoded channel(s) from the message. Chainable.

- `Message removeChannels(MsgChannelSet channels)`
  Subtracts `channels` from the message's channel set. Chainable.

- `bool isEmpty()`
  Returns `true` when both `content` and `attachments` are empty.

## Usage Example

```qml
import QtQuick
import Qool.Chat

// Object-literal construction
var m1 = qoolmessage {
    content: "hello"
    note: "from QML"        // becomes an attachment
}

// Chained API
var m2 = qoolmessage { content: "directed" }
        .addChannel("lobby")
        .attach("level", 3)

// Combined with Beeper's targeted post:
myBeeper.postMessage("lobby", m2)
```
