import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs

Control {
    id: root
    property color value: defaultValue
    property color defaultValue: "darkgrey"
    property string name

    padding: 4
    contentItem: Item {
        implicitWidth: 60
        implicitHeight: 20

        Item {
            id: selectorFace
            anchors.fill: parent
            visible: mArea.containsMouse
            Rectangle {
                id: rainbow
                anchors.fill: parent
                radius: 2
                border.width: 0
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: Qt.hsva(0, 1, 1, 1)
                    }
                    GradientStop {
                        position: 0.1
                        color: Qt.hsva(0.1, 1, 1, 1)
                    }
                    GradientStop {
                        position: 0.2
                        color: Qt.hsva(0.2, 1, 1, 1)
                    }
                    GradientStop {
                        position: 0.3
                        color: Qt.hsva(0.3, 1, 1, 1)
                    }
                    GradientStop {
                        position: 0.4
                        color: Qt.hsva(0.4, 1, 1, 1)
                    }
                    GradientStop {
                        position: 0.5
                        color: Qt.hsva(0.5, 1, 1, 1)
                    }
                    GradientStop {
                        position: 0.6
                        color: Qt.hsva(0.6, 1, 1, 1)
                    }
                    GradientStop {
                        position: 0.7
                        color: Qt.hsva(0.7, 1, 1, 1)
                    }
                    GradientStop {
                        position: 0.8
                        color: Qt.hsva(0.8, 1, 1, 1)
                    }
                    GradientStop {
                        position: 0.9
                        color: Qt.hsva(0.9, 1, 1, 1)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.hsva(1, 1, 1, 1)
                    }
                }
            }

            Rectangle {
                id: luminance
                anchors.fill: parent
                radius: 2
                border.width: 0
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {
                        position: 0
                        color: Qt.hsva(0, 0, 1, 1)
                    }
                    GradientStop {
                        position: 0.5
                        color: Qt.hsva(0, 0, .5, 0)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.hsva(0, 0, 0, 1)
                    }
                }
            }
        }//selectorFace

        Text {
            text: root.name
            anchors.centerIn: parent
            color: palette.text
        }

        MouseArea {
            id: mArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true

            onPositionChanged: e => {
                if (e.buttons & Qt.LeftButton) {
                    let hue = width / e.x;
                    let luminance = 1 - height / e.y;
                    root.value = Qt.hsva(hue, 1, luminance, 1);
                }
            }

            onClicked: e => {
                if (e.buttons & Qt.RightButton) {
                    dialog.selectedColor = root.value;
                    dialog.open();
                }
            }
        }
    }//contentItem

    background: Rectangle {
        radius: 6
        color: root.value
        border.color: palette.text
        border.width: mArea.pressed ? 2 : 0
    }

    ColorDialog {
        id: dialog
        onAccepted: {
            root.value = dialog.selectedColor;
        }
    }
}
