import QtQuick
import QtQuick.Controls

Control {
    id: root

    ButtonGroup {
        id: pageButtons
    }

    contentItem: ListView {
        model: PageListModel {}
        delegate: Button {
            text: model.title
            ToolTip.text: model.note
            checkable: true
            ButtonGroup.group: pageButtons
            width: ListView.view.width
        }
        implicitWidth: 100
    }
}
