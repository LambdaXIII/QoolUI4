import QtQuick
import QtQuick.Templates as T
import Qool

T.AbstractButton {
    id: root

    property url url: text

    property alias cursorShape: bgArea.cursorShape

    //设为null即可取消下划线效果
    property Item underline: Rectangle {
        border.width: 0
        color: mainText.color
        height: 1
        width: root.availableWidth
        x: root.leftPadding
        y: root.topPadding + root.availableHeight
    }

    Binding {
        when: root.underline
        root.underline.parent: root
    }

    font.pixelSize: Style.textSize

    background: MouseArea {
        id: bgArea
        implicitWidth: 10
        implicitHeight: 10
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
    }

    contentItem: Text {
        id: mainText
        text: root.text
        font: root.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: root.down ? Style.highlight : Style.link
    }

    implicitWidth: {
        const w1 = leftInset + implicitBackgroundWidth + rightInset;
        const w2 = leftPadding + implicitContentWidth + rightPadding;
        return Math.max(w1, w2);
    }

    implicitHeight: {
        const h1 = topInset + implicitBackgroundHeight + bottomInset;
        const h2 = topPadding + implicitContentHeight + bottomPadding;
        return Math.max(h1, h2);
    }

    function openUrlExternally() {
        Qt.openUrlExternally(root.url);
    }

    onClicked: openUrlExternally() //allowed to be replaced
}
