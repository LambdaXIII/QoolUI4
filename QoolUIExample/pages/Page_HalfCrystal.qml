// HalfCrystal 展示与验证页：四方向切换/菱形保留/样式通道/非方形尺寸/
// 掩码 hover 演示，与 Crystal 同台展示（T07）。
//
// 尺寸约定：HalfCrystal implicit 20×20（组件默认自洽）。Qt Quick Layouts
// 中 implicit > 0 优先于显式 width/height（qquicklayout.cpp GATHER PREFERRED
// SIZE HINTS）——布局容器内实例须用 Layout.preferredWidth/Height 显式指定
// 尺寸（本页非方形组即此用法）。
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Qool
import Qool.Controls
import "components"

BasicPage {
    id: root
    title: qsTr("HalfCrystal")
    note: qsTr("三角版 Crystal——四点模型方向切换/菱形保留/掩码/动画")

    implicitHeight: cc.implicitHeight

    Column {
        id: cc
        spacing: 20

        // —— 方向切换 demo ——
        QoolControl {
            title: qsTr("方向切换")
            width: 320

            contentItem: ColumnLayout {
                HalfCrystal {
                    id: demo
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 120
                    width: 120
                    height: 120
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Button {
                        text: "N"
                        checkable: true
                        checked: demo.direction === Qore.N
                        onClicked: demo.direction = Qore.N
                    }
                    Button {
                        text: "S"
                        checkable: true
                        checked: demo.direction === Qore.S
                        onClicked: demo.direction = Qore.S
                    }
                    Button {
                        text: "W"
                        checkable: true
                        checked: demo.direction === Qore.W
                        onClicked: demo.direction = Qore.W
                    }
                    Button {
                        text: "E"
                        checkable: true
                        checked: demo.direction === Qore.E
                        onClicked: demo.direction = Qore.E
                    }
                }

                CheckBox {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("动画")
                    checked: root.Style.animationEnabled
                    onToggled: root.Style.animationEnabled = checked
                }
            }
        }

        // —— 菱形保留态 ——
        QoolControl {
            title: qsTr("菱形保留态")
            width: 320

            contentItem: Row {
                spacing: 12
                HalfCrystal {
                    width: 80
                    height: 80
                    direction: Qore.N
                }
                HalfCrystal {
                    width: 80
                    height: 80
                    direction: Qore.Unknown
                }
                HalfCrystal {
                    width: 80
                    height: 80
                    direction: Qore.NW
                }
            }
        }

        // —— 样式通道 ——
        QoolControl {
            title: qsTr("样式通道")
            width: 320

            contentItem: HalfCrystal {
                id: styled
                width: 100
                height: 100
                color: root.Style.accent
                fillGradient: LinearGradient {
                    x1: 0
                    y1: 0
                    x2: styled.width
                    y2: styled.height
                    GradientStop {
                        position: 0
                        color: "#33ccff"
                    }
                    GradientStop {
                        position: 1
                        color: "#ff8800"
                    }
                }
            }
        }

        // —— 非方形尺寸 ——
        QoolControl {
            title: qsTr("非方形尺寸")
            width: 320

            contentItem: ColumnLayout {
                HalfCrystal {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 90
                    width: 180
                    height: 90
                    direction: Qore.N
                }
                HalfCrystal {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 140
                    width: 90
                    height: 140
                    direction: Qore.E
                }
            }
        }

        // —— 掩码 hover 演示（与 Crystal 同台对照）——
        QoolControl {
            title: qsTr("掩码 hover 演示")
            width: 320

            contentItem: ColumnLayout {
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    HalfCrystal {
                        id: masked
                        width: 120
                        height: 120
                        MouseArea {
                            id: maskedMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }

                    Crystal {
                        width: 80
                        height: 80
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: maskedMouse.containsMouse ? qsTr("HalfCrystal hovered") : qsTr("HalfCrystal idle")
                    color: maskedMouse.containsMouse ? "#33ccff" : root.Style.text
                }
            }
        }
    } //cc
}
