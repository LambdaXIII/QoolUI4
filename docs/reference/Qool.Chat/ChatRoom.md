# ChatRoom

A chat room: the registration container for a group of `Beeper` instances
and the entry point for message distribution.

`ChatRoom` organizes a set of `Beeper`s into the same channel space. QML
child elements are registered automatically (the default property is
`beepers`); registration and deregistration are forwarded through
`ChatRoomManager` to the server thread backing this room.

## Properties

- `beepers : list<Beeper>` (read-only, constant)
  The default property. Holds the beepers registered in this room. QML child
  elements declared inside the room are automatically registered
  (`signIn`).

- `name : string` (read/write, notifies `nameChanged`)
  The server channel name of this room. Assigning a name establishes the
  connection to `ChatRoomManager::server(name)`, reusing a cached server
  instance for the same name (server instances live on a dedicated thread).
  If left unset, `componentComplete` fills in the default `"GLOBAL"`. Once
  the server connection is established, already-registered beepers are
  re-sent to the server (see "Registration timing" below).

## Signals

- `wannaSignIn(beeper)`, `wannaSignOut(beeper)`, `wannaPostMessage(message)`
  Internal plumbing signals, connected to the room's server through
  `Qt::BlockingQueuedConnection`. They are emitted by registration,
  deregistration and posting, respectively, and forwarded to the server
  thread.

- `nameChanged()`
  Emitted when `name` changes.

## Methods

- `void postMessage(Message message)`
  Posts `message` using the channels the message itself carries.

- `void postMessage(string channels, Message message)`
  Appends `channels` to `message` and posts it — the targeted "send to the
  given channels" convenience overload. Both overloads coexist; they are not
  redundant.

- `void dumpInfo() const`
  Debug helper that prints the current server name and the registered
  beepers. If no server is connected (no `name` assigned) the server prints
  as `(none)`.

## Registration timing (deliberate design)

Registration is deliberately deferred until the component is complete and
its properties are ready. Under QML property evaluation order, a beeper's
`chatRoom` assignment may run before this room's `name` is assigned, so its
sign-in signal could fire before the server connection exists and be lost.
After the server connection is established, registration is re-sent
idempotently by name (already-registered beepers are ignored); with the
normal declaration order (`name` first) this is zero-cost. The server reads
each beeper's channels in real time during delivery (`trySend →
beeper->channels()`), so registration timing does not affect channel
correctness.

## Usage Example

```qml
import QtQuick
import Qool.Chat

ChatRoom {
    id: room
    name: "lobby"          // must come before beepers for zero-cost reg

    Beeper { id: alice }
    Beeper { id: bob }

    Component.onCompleted: {
        // alice posts on the room's channel space
        alice.postMessage(qoolmessage { content: "hi" })
    }
}
```

> Note: `ChatRoom` is a QML-registered entity (`QML_ELEMENT`). On the C++
> side, obtain a server directly via
> `ChatRoomManager::instance()->server(name)`.
