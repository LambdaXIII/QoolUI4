import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Qool.File
import Qool

T.Control {
    id: root

    property fileinfo fileInfo

    property int preferredIconSize: 32

    contentItem: ColumnLayout {
        Image {
            id: img
            fillMode: Image.PreserveAspectFit
            source: root.fileInfo.iconUrl
            Layout.fillWidth: true
            Layout.preferredWidth: root.preferredIconSize
            Layout.preferredHeight: root.preferredIconSize
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            id: nameText
            text: root.fileInfo.fileName
            elide: Text.ElideMiddle
            font.pixelSize: root.Style.decorativeTextSize
            color: root.Style.text
            BasicTextBehavior on text {}
            Layout.alignment: Qt.AlignHCenter
        }
    }

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding
}
