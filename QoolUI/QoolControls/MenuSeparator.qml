import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Basic
import Qool

Basic.MenuSeparator {
    id: root

    property string text
    property color color: Style.alternateBase

    font.pixelSize: Style.decorativeTextSize

    contentItem: RowLayout {
        spacing: 2
        Rectangle {
            height: 2
            radius: 1
            border.width: 0
            color: root.color
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
        }

        Text {
            text: root.text
            color: root.color
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font: root.font
            elide: Text.ElideMiddle
            visible: root.text
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            height: 2
            radius: 1
            border.width: 0
            color: root.color
            visible: root.text
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
        }
    }//contentItem

    leftPadding: 4
    rightPadding: 4
}
