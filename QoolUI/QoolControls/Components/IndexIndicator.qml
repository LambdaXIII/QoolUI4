import QtQuick
import QtQuick.Templates as T
import QtQuick.Layouts

T.Control {
    id: root

    property int currentIndex: -1

    property real implicitDelegateWidth: 4
    property real implicitDelegateHeight: 4

    property Component delegate: Rectangle {
        required property int index
        readonly property bool highlighted: index == root.currentIndex
        color: highlighted ? root.Style.highlight : root.Style.buttonText
        opacity: highlighted ? 1 : 0.35
        implicitWidth: root.implicitDelegateWidth
        implicitHeight: root.implicitDelegateHeight
    }

    property alias model: repeater.model

    property int orientation: Qt.Vertical

    contentItem: Grid {
        id: grid
        // flow: Grid.TopToBottom
        layoutDirection: root.mirrored ? Qt.LeftToRight : Qt.RightToLeft

        Repeater {
            id: repeater
            delegate: root.delegate
        }

        // rows: Math.floor(grid.height / root.implicitDelegateHeight)
        columnSpacing: 1
        rowSpacing: 1

        Binding {
            when: root.orientation === Qt.Vertical
            grid.flow: Grid.TopToBottom
            grid.rows: Math.floor(grid.height / root.implicitDelegateHeight)
        }

        Binding {
            when: root.orientation === Qt.Horizontal
            grid.flow: Grid.LeftToRight
            grid.columns: Math.floor(grid.width / root.implicitDelegateWidth)
        }
    }

    background: Item {
        implicitWidth: 4
        implicitHeight: 20
    }

    padding: 6

    implicitWidth: {
        let w1 = leftPadding + implicitContentWidth + rightPadding;
        let w2 = leftInset + implicitBackgroundWidth + rightInset;
        return Math.max(w1, w2);
    }
    implicitHeight: {
        let h1 = topPadding + implicitContentHeight + bottomPadding;
        let h2 = topInset + implicitBackgroundHeight + bottomInset;
        return Math.max(h1, h2);
    }
}
