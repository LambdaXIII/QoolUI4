import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string title
    property string displayValue
    property string commet

    property color titleColor: palette.accent
    property color valueColor: palette.buttonText
    property color commetColor: palette.toolTipText

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
            font.pixelSize: 8
            wrapMode: Text.NoWrap
            color: root.titleColor
            Layout.alignment: Qt.AlignTop
        }
        Text {
            id: valueText
            text: root.displayValue == "" ? "N/A" : root.displayValue
            font.pixelSize: 10
            leftPadding: 4
            rightPadding: 4
            wrapMode: Text.NoWrap
            color: root.valueColor
            Layout.preferredWidth: implicitWidth
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: implicitHeight
        }
        Text {
            id: commetText
            text: root.commet
            visible: root.commet != ""
            font.pixelSize: 8
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            Layout.fillWidth: true
            Layout.rowSpan: 2
            Layout.preferredHeight: implicitHeight
        }
    }
}
