import QtQuick
import QtQuick.Controls
import Qool.Controls

Control {
    id: root

    ButtonGroup {
        id: pageButtons
    }

    contentItem: ListView {
        model: PageListModel {}
        delegate: SimpleButton {
            text: model.title
            ToolTip.text: model.note
            checkable: true
            ButtonGroup.group: pageButtons
            width: ListView.view.width
        }
        implicitWidth: 100
    }
}
