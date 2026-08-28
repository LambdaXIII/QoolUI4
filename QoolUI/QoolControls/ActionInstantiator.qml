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

//TODO: 考虑移入某模块private或Components
