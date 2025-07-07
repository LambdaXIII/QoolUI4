import QtQuick
import QtQuick.Layouts
import Qool

Item {
    id: root

    property string title
    property string displayValue
    property string commet

    property color titleColor: Style.accent
    property color valueColor: Style.buttonText
    property color commetColor: Style.toolTipText

    implicitWidth: contentLayout.implicitWidth
    implicitHeight: contentLayout.implicitHeight

    GridLayout {
        id: contentLayout
        anchors.fill: parent
        columnSpacing: 0
        rowSpacing: 0
        columns: 2
        Text {
            id: titleText
            text: root.title
            visible: root.title != ""
            font.family: PixelFont.family
            font.pixelSize: 16
            wrapMode: Text.NoWrap
            color: root.titleColor
            Layout.alignment: Qt.AlignTop
            antialiasing: false
        }
        Text {
            id: valueText
            text: root.displayValue == "" ? "N/A" : root.displayValue
            font: PixelFont.normal
            leftPadding: 4
            rightPadding: 4
            wrapMode: Text.NoWrap
            color: root.valueColor
            Layout.preferredWidth: implicitWidth
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: implicitHeight
            antialiasing: false
        }
        Text {
            id: commetText
            text: root.commet
            visible: root.commet != ""
            font.pixelSize: 10
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            Layout.fillWidth: true
            Layout.rowSpan: 2
            Layout.preferredHeight: implicitHeight
        }
    }
}
