import QtQuick
import QtQuick.Controls

Instantiator {
    id: root

    default property list<Action> actions

    model: actions

    delegate: ClickableText {
        action: modelData
    }
}
