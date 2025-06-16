import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

Control {
    id: root

    property string title: qsTr("属性")
    property alias slider: slider

    contentItem: RowLayout {
        Text {
            text: root.title
            Layout.preferredWidth: implicitWidth
        }
        Slider {
            id: slider
            Layout.preferredWidth: 100
            Layout.fillWidth: true
        }
        Text {
            text: {
                let a = Math.round(slider.value * 100)
                return a / 100
            }
            Layout.preferredWidth: 30
            horizontalAlignment: Text.AlignRight
        }
    }
}
