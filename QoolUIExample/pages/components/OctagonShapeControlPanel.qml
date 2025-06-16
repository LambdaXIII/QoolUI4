import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Control {
    id: root

    readonly property real shapeWidth: widthControl.slider.value
    readonly property real shapeHeight: heightControl.slider.value
    readonly property real borderWidth: borderWidthControl.slider.value
    readonly property real cutSizeTL: tlCutSizeControl.slider.value
    readonly property real cutSizeTR: trCutSizeControl.slider.value
    readonly property real cutSizeBL: blCutSizeControl.slider.value
    readonly property real cutSizeBR: brCutSizeControl.slider.value

    contentItem: ColumnLayout {
        SimpleSliderControl {
            id: widthControl
            title: qsTr("宽度")
            slider {
                from: 20
                to: 800
                value: 400
            }
            Layout.fillWidth: true
        }
        SimpleSliderControl {
            id: heightControl
            title: qsTr("高度")
            slider {
                from: 20
                to: 800
                value: 200
            }
            Layout.fillWidth: true
        }
        SimpleSliderControl {
            id: borderWidthControl
            title: qsTr("边缘宽度")
            slider {
                from: 0
                to: 100
                value: 5
            }
            Layout.fillWidth: true
        }
        SimpleSliderControl {
            id: tlCutSizeControl
            title: qsTr("左上切角")
            slider {
                from: 0
                to: 1000
                value: 20
            }
            Layout.fillWidth: true
        }
        SimpleSliderControl {
            id: trCutSizeControl
            title: qsTr("右上切角")
            slider {
                from: 0
                to: 1000
                value: 0
            }
            Layout.fillWidth: true
        }
        SimpleSliderControl {
            id: blCutSizeControl
            title: qsTr("左下切角")
            slider {
                from: 0
                to: 1000
                value: 0
            }
            Layout.fillWidth: true
        }
        SimpleSliderControl {
            id: brCutSizeControl
            title: qsTr("右下切角")
            slider {
                from: 0
                to: 1000
                value: 0
            }
            Layout.fillWidth: true
        }
    } //contentITem
    padding: 5

    background: Rectangle {
        color: "cyan"
        opacity: 0.5
        border.width: 2
        border.color: "black"
        radius: 5
    }
}
