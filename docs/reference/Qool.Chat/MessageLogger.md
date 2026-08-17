# MessageLogger

A message-logging app: records the messages a `Beeper` receives and exposes
them as a list.

`MessageLogger` is the default implementation of `BasicBeeperApp`. Once
installed onto a `Beeper`, it appends each arriving message to the
`messages` list for UI display or debugging.

## Properties

- `messages : list<Message>` (read-only, notifies `messagesChanged`)
  The accumulated received messages, in arrival order.

- `maxLength : int` (read/write, default `50`)
  Controls how many messages are retained:
  - positive: keep the most recent `maxLength` messages, dropping from the
    head when the limit is exceeded;
  - `0`: keep nothing (appends are skipped and existing messages are
    cleared — the list is always empty, a deliberately self-consistent
    semantics);
  - negative: unlimited (messages are only appended, never trimmed).

- `length : int` (read-only, notifies `lengthChanged`)
  The current number of retained messages.

## Signals

- `messagesChanged()`
  Emitted when the `messages` list changes.

- `lengthChanged()`
  Emitted when `length` changes.

Inherited from `BasicBeeperApp`: `messageRecieved(Message)` (the incoming
message signal forwarded from the host beeper).

## Methods

- `void clear()`
  Clears all retained messages.

- `string appName()`
  Reimplemented from `BasicBeeperApp`; returns `"MessageLogger"`.

- `void appendMessage(Message message)`
  Slot that appends an arriving message. It drops a message identical to the
  last one (`operator==` compares the identity fields; a copy that produced a
  new identity is not considered a duplicate).

## Single-thread contract (no lock, deliberate design)

All message arrival happens on the main thread (`messageRecieved` is
dispatched via `MessageEvent` on the main thread and consumed by this
class's slot), and there are no cross-thread callers — so a mutex would be
dead code and is deliberately omitted. If a cross-thread append is ever
introduced, it must be forwarded to this object's thread via a queued
connection rather than by re-adding a lock.

## Usage Example

```qml
import QtQuick
import Qool.Chat

ChatRoom {
    name: "lobby"
    Beeper {
        // default property: the logger is installed automatically
        MessageLogger {
            id: log
            maxLength: 100
        }
        // React to new messages
        onMessageRecieved: (m) => console.log("got", m.content)
    }
}
```
