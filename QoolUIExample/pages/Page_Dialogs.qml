// Dialogs 展示页：DialogSurface 独立面板 / 拼进 Popup 的 overlay 用法 /
// QoolDialog 窗口对话框（Esc 与按钮双关闭路径、显式尺寸、modality）。
import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import Qool.Dialogs

BasicPage {
    id: root
    title: qsTr("对话框")
    note: qsTr("QoolDialog 窗口对话框与 DialogSurface 表面件")

    // 最近一次对话框结果反馈（accepted/rejected）
    property string lastResult: qsTr("（尚无结果）")

    implicitHeight: cc.implicitHeight

    Column {
        id: cc
        spacing: 20

        // —— DialogSurface 独立面板（title 入口）——
        QoolControl {
            title: qsTr("Surface 独立面板")
            width: 360
            height: 200

            DialogSurface {
                id: surface1
                anchors.fill: parent
                anchors.margins: 16
                title: qsTr("确认操作")

                content: Item {
                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: qsTr("标题由 title 设置；背景为 dialog 主题 token——TL 切角、accent 描边、window 底色。切换主题观察变化。")
                        color: root.Style.text
                    }
                }
            }
        }

        // —— titleItem 替换默认标题渲染 ——
        QoolControl {
            title: qsTr("titleItem 替换标题")
            width: 360
            height: 160

            DialogSurface {
                id: surface2
                anchors.fill: parent
                anchors.margins: 16

                titleItem: Row {
                    spacing: 6
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: surface2.backgroundSettings.borderWidth + 1
                        rightMargin: surface2.backgroundSettings.borderWidth + 1
                    }
                    Rectangle {
                        width: 10
                        height: 10
                        color: root.Style.accent
                        rotation: 45
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: qsTr("自定义标题（图标 + 文本）")
                        color: root.Style.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                content: Item {
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("标题渲染被 titleItem 接管。")
                        color: root.Style.text
                    }
                }
            }
        }

        // —— DialogSurface 拼进 Popup（overlay 语义来自 Popup）——
        QoolControl {
            title: qsTr("Surface + Popup（overlay）")
            width: 360

            contentItem: Column {
                spacing: 8

                Button {
                    text: qsTr("打开 overlay 对话框")
                    onClicked: overlayPopup.open()
                }

                Text {
                    text: qsTr("dim 遮罩与点外/Esc 关闭由 Popup 提供，Surface 只负责表面。")
                    color: root.Style.text
                    wrapMode: Text.Wrap
                    width: parent.width
                }
            }
        }

        // —— QoolDialog 基础：Esc 与按钮两条关闭路径 ——
        QoolControl {
            title: qsTr("QoolDialog 基础")
            width: 360

            contentItem: Column {
                spacing: 8

                Button {
                    text: qsTr("打开对话框")
                    onClicked: basicDialog.open()
                }

                Text {
                    text: qsTr("最近结果: ") + root.lastResult
                    color: root.Style.accent
                }

                Text {
                    text: qsTr("对话框打开期间宿主窗口不可交互（默认 Qt.WindowModal）。")
                    color: root.Style.text
                    wrapMode: Text.Wrap
                    width: parent.width
                }
            }
        }

        // —— QoolDialog 显式尺寸 ——
        QoolControl {
            title: qsTr("QoolDialog 显式尺寸")
            width: 360

            contentItem: Column {
                spacing: 8

                Button {
                    text: qsTr("打开固定尺寸对话框（420×260）")
                    onClicked: sizedDialog.open()
                }

                Text {
                    text: qsTr("不设尺寸时窗口由内容反推；显式赋值时内容区随之扩展。")
                    color: root.Style.text
                    wrapMode: Text.Wrap
                    width: parent.width
                }
            }
        }

        // —— modality 显式可改 ——
        QoolControl {
            title: qsTr("Modality")
            width: 360

            contentItem: Column {
                spacing: 8

                CheckBox {
                    id: nonModalCheck
                    text: qsTr("非模态（Qt.NonModal）")
                }

                Row {
                    spacing: 8
                    Button {
                        text: qsTr("打开对话框")
                        onClicked: {
                            modalityDialog.modality = nonModalCheck.checked
                                ? Qt.NonModal : Qt.WindowModal
                            modalityDialog.open()
                        }
                    }

                    Button {
                        text: qsTr("宿主按钮（模态下不可点）")
                        onClicked: resultLabel.text = qsTr("宿主按钮被点击")
                    }
                }

                Text {
                    id: resultLabel
                    text: qsTr("模态时本页控件不可交互；非模态时可交互。")
                    color: root.Style.text
                    wrapMode: Text.Wrap
                    width: parent.width
                }
            }
        }
    }

    // —— Popup overlay ——
    Popup {
        id: overlayPopup
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        // Surface 自带 QoolBox 背景；Popup 默认背景会在切角外露出一圈
        background: Item {}
        width: 360
        height: 220
        anchors.centerIn: Overlay.overlay

        DialogSurface {
            anchors.fill: parent
            title: qsTr("overlay 对话框")

            content: Item {
                Text {
                    anchors.centerIn: parent
                    width: parent.width
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("按 Esc 或点击遮罩外部关闭。")
                    color: root.Style.text
                }
            }
        }
    }

    // —— QoolDialog 基础：内容反推尺寸 ——
    QoolDialog {
        id: basicDialog
        title: qsTr("删除项目？")
        onAccepted: root.lastResult = qsTr("accepted")
        onRejected: root.lastResult = qsTr("rejected")

        content: Column {
            spacing: 12

            Text {
                text: qsTr("该操作无法撤销。")
                color: root.Style.windowText
            }

            Row {
                spacing: 8
                Button {
                    text: qsTr("删除")
                    onClicked: basicDialog.accept()
                }
                Button {
                    text: qsTr("取消")
                    onClicked: basicDialog.reject()
                }
            }
        }
    }

    // —— QoolDialog 显式尺寸：内容区扩展 ——
    QoolDialog {
        id: sizedDialog
        title: qsTr("固定尺寸")
        width: 420
        height: 260
        onAccepted: root.lastResult = qsTr("accepted")
        onRejected: root.lastResult = qsTr("rejected")

        content: Column {
            spacing: 12

            Text {
                text: qsTr("窗口 420×260 由显式赋值决定，内容区随之扩展。")
                color: root.Style.windowText
            }

            Button {
                text: qsTr("确定")
                onClicked: sizedDialog.accept()
            }
        }
    }

    // —— modality 演示 ——
    QoolDialog {
        id: modalityDialog
        title: qsTr("模态演示")
        onAccepted: root.lastResult = qsTr("accepted")
        onRejected: root.lastResult = qsTr("rejected")

        content: Column {
            spacing: 12

            Text {
                text: qsTr("modality 已在打开前显式设置。")
                color: root.Style.windowText
            }

            Button {
                text: qsTr("关闭")
                onClicked: modalityDialog.reject()
            }
        }
    }
}
