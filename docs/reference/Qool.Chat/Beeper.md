# Beeper

A chat-room member that subscribes to channels and sends and receives
messages, and that hosts a set of `BasicBeeperApp` applications.

`Beeper` is the message terminal of the Qool.Chat module. Construction
generates a unique `name` (`BEEPER_<6 random chars>`) and subscribes the
`ALL` channel; joining a `ChatRoom` then lets the beeper send and receive
messages through the server. `apps` is the default property
(`DefaultProperty`), so child elements declared in QML — such as a
`MessageLogger` — are installed onto this `Beeper` automatically, with their
`target` pointing back to this beeper.

## Properties

- `apps : list<BasicBeeperApp>` (read-only, constant)
  The default property. Holds the applications installed on this beeper.
  Declaring child elements in QML appends them here; each appended app whose
  `target` is still null is pointed at this beeper.

- `channels : MsgChannelSet` (read/write, notifies `channelsChanged`)
  Determines which channels' messages this beeper receives. The getter and
  setter are deliberately mutex-protected: the server thread reads this set
  across threads (via `trySend`), racing a main-thread write would be a
  data race (`QSet` concurrent read/write is undefined behavior), so the
  set is copied under the lock.

- `channel : string` (read/write, notifies `channelsChanged`)
  A convenience decodable-string form of `channels`. Writing a value decodes
  it into the underlying `channels` set. The string uses the same
  space/comma/semicolon-separated encoding understood by
  `MsgChannelSet::decode`.

- `name : QByteArray` (read/write)
  The unique beeper name, generated on construction and used as the sender
  identity for posted messages. The macro getter is deliberately not locked:
  `QByteArray`'s implicit sharing (atomic reference counting plus a single
  pointer) is safe in the "read pointer, then copy" window, the standard
  cross-thread-copy pattern for Qt implicitly shared types.

- `chatRoom : ChatRoom` (read/write)
  The room this beeper belongs to. Assigning a room signs this beeper out of
  its previous room and into the new one.

- `enabled : bool` (default `true`)
  Whether this beeper accepts incoming messages. When `false`, received
  messages are ignored.

## Signals

- `messageRecieved(Message message)`
  Emitted when a message arrives for this beeper. It is emitted on the
  thread in which the `Beeper` lives: the server delivers asynchronously via
  `postEvent`, and this object consumes it through `customEvent`. Emitted
  only when `enabled` is `true`.

- `channelsChanged()`
  Emitted when `channels` (or the `channel` convenience form) changes.

- `chatRoomChanged()`
  Emitted when `chatRoom` changes.

- `nameChanged()`
  Emitted when `name` changes.

- `enabledChanged()`
  Emitted when `enabled` changes.

## Methods

- `void postMessage(Message message)`
  Posts `message` using the channels the message itself carries. Before
  posting, the sender ID is set to this beeper's own `name` and the beeper's
  own `channels` are added to the message. If no server is connected, the
  post is rejected with a warning.

- `void postMessage(string channels, Message message)`
  Posts `message`, appending the given `channels` to it before sending —
  the targeted "send to these channels" convenience overload. The sender ID
  and this beeper's own channels are filled in as with the single-argument
  form. If no server is connected, the post is rejected with a warning.

## Usage Example

```qml
import QtQuick
import Qool.Chat

ChatRoom {
    id: room
    name: "lobby"

    Beeper {
        id: me
        // messageRecieved handled by a MessageLogger app
        MessageLogger {
            id: log
        }
    }

    Beeper {
        id: peer
    }

    // send a message on the room's own channel
    function send() {
        me.postMessage(qoolmessage { content: "hello" })
    }

    // send directed to a specific channel
    function sendTo(ch) {
        me.postMessage(ch, qoolmessage { content: "directed" })
    }
}
```

> Note: The value type used in QML is spelled `qoolmessage` (see the
> `Message` reference).
