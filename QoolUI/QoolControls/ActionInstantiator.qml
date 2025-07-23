import QtQuick
import QtQuick.Controls

Repeater {
    id: root

    default property list<Action> actions

    model: actions

    delegate: ClickableText {
        action: modelData
    }
}
