import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qool.Debug

Control {
    id: root

    readonly property real shapeWidth: widthSlider.value
    readonly property real shapeHeight: heightSlider.value
    readonly property real borderWidth: borderWidthSlider.value
    readonly property real cutSizeTL: tlSlider.value
    readonly property real cutSizeTR: trSlider.value
    readonly property real cutSizeBL: blSlider.value
    readonly property real cutSizeBR: brSlider.value
    readonly property color fillColor: fillColorButton.value
    readonly property color borderColor: borderColorButton.value

    signal wannaDumpInfo

    contentItem: ColumnLayout {
        NumberSlider {
            id: widthSlider
            name: qsTr("图形宽度")
            defaultValue: 400
            from: 25
            to: 800
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }
        NumberSlider {
            id: heightSlider
            name: qsTr("图形高度")
            defaultValue: 250
            from: 25
            to: 800
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }
        NumberSlider {
            id: borderWidthSlider
            name: qsTr("描边宽度")
            defaultValue: 6
            from: 0
            to: 200
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }

        NumberSlider {
            id: tlSlider
            name: qsTr("左上切角距离")
            defaultValue: 20
            from: 0
            to: 300
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }
        NumberSlider {
            id: trSlider
            name: qsTr("右上切角距离")
            defaultValue: 0
            from: 0
            to: 300
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }
        NumberSlider {
            id: blSlider
            name: qsTr("左下切角距离")
            defaultValue: 0
            from: 0
            to: 300
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }
        NumberSlider {
            id: brSlider
            name: qsTr("右下切角距离")
            defaultValue: 0
            from: 0
            to: 300
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }
        RowLayout {
            Layout.fillWidth: true
            ColorButton {
                id: fillColorButton
                defaultValue: palette.accent
                name: qsTr("图形颜色")
            }
            ColorButton {
                id: borderColorButton
                defaultValue: palette.shadow
                name: qsTr("描边颜色")
            }
        }
        Item {
            Layout.fillHeight: true
        }
        ActionButton {
            Layout.fillWidth: true
            text: qsTr("Dump信息至控制台")
            onClicked: root.wannaDumpInfo()
        }
    } //contentITem
    padding: 5

    background: Rectangle {
        color: palette.window
        opacity: 0.5
    }
}
