import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Color
import Qool.Controls
import "components"

BasicPage {
    id: root

    title: qsTr("颜色控件")
    note: qsTr("操纵颜色的模块")

    implicitHeight: cc.implicitHeight

    Component.onCompleted: mainColor.color = Style.highlight

    // 共享颜色源：全页唯一 ColorAssistant，四面板/预览器绑定它，
    // picker/editor 经 Connections 双向同步（v3 同构）。
    ColorAssistant {
        id: mainColor
    }

    Column {
        id: cc
        spacing: 15

        // Floater {
        //     content: QoolControl {
        //         title: qsTr("当前颜色")
        //         contentItem: ColorPreviewer {
        //             id: previewer
        //             colorAssistant: mainColor
        //             implicitWidth: 120
        //             implicitHeight: 25
        //         }
        //         QoolTip {
        //             text: qsTr("悬停此处显示提示：快速取色/快速输入与下方全部面板共享当前颜色，任意一处修改全页联动")
        //             color: Style.cyan
        //         }
        //     }
        // }

        QoolControl {
            id: editorControl
            title: qsTr("色值/色彩名编辑器")
            contentItem: ColorEdit {
                id: editor
                Layout.fillWidth: true
                onCurrentColorChanged: mainColor.color = currentColor
                QoolTip {
                    text: qsTr("点击进入编辑，输入颜色名或 #RRGGBB / #AARRGGBB，回车或失焦提交")
                    color: Style.cyan
                }
            }
        }

        QoolControl {
            id: pickerControl
            title: qsTr("快速取色器")
            contentItem: ColorQuickPicker {
                id: picker
                Layout.fillWidth: true
                onCurrentColorChanged: mainColor.color = currentColor
            }
        }

        Connections {
            target: mainColor
            function onColorChanged() {
                picker.currentColor = mainColor.color;
                editor.currentColor = mainColor.color;
            }
        }

        SectionBar {
            width: root.width
        }

        // ---- HSV 面板 ----
        QoolControl {
            // width: hsvPanel.width
            // height: hsvPanel.height
            title: qsTr("HSV色轮面板")
            contentItem: HSVPanel {
                id: hsvPanel
                colorAssistant: mainColor
            }
            QoolTip {
                text: qsTr("HSV 色彩空间：在渐变轮上拖动取色，明度/透明度滑块调节，双击重置")
                color: Style.yellow
                z: -1
            }
        }

        SectionBar {
            width: root.width
        }

        // ---- HSL 面板 ----
        QoolControl {
            // width: hslPanel.width
            // height: hslPanel.height
            title: qsTr("HSL色彩选择面板")
            contentItem: HSLPanel {
                id: hslPanel
                colorAssistant: mainColor
            }
            QoolTip {
                text: qsTr("HSL 色彩空间：在渐变方块上取色，亮度/透明度滑块调节，双击重置")
                color: Style.green
                z: -1
            }
        }

        SectionBar {
            width: root.width
        }

        // ---- RGB 面板 ----
        QoolControl {
            title: qsTr("RGB色彩选择面板")
            // width: rgbPanel.width
            // height: rgbPanel.height
            contentItem: RGBPanel {
                id: rgbPanel
                colorAssistant: mainColor
            }
            QoolTip {
                text: qsTr("RGB 色彩空间：红/绿/蓝与透明度分量调节，支持直接输入数值")
                color: Style.blue
                z: -1
            }
        }

        SectionBar {
            width: root.width
        }

        // ---- CMYK 面板 ----
        QoolControl {
            title: qsTr("CMYK滑块选择")
            contentItem: CMYKPanel {
                id: cmykPanel
                colorAssistant: mainColor
            }
            QoolTip {
                text: qsTr("CMYK 色彩空间：青/品红/黄/黑四色分量调节，面向印刷色域")
                color: Style.cyan
                z: -1
            }
        }

        SectionBar {
            width: root.width
        }

        // ---- 色名列表（提示挂分区标题：列表悬停驱动下划线/高亮，见文件头说明）----

        QoolControl {
            title: qsTr("色彩名称列表")
            contentItem: ColorNameList {
                colorAssistant: mainColor
            }
            height: 450
            width: 400
            QoolTip {
                text: qsTr("按分类浏览颜色名，点选色名即应用到当前颜色")
                color: Style.green
            }
        }

        SectionBar {
            width: root.width
        }

        // ---- 色银行（提示挂分区标题：槽位悬停驱动 L/S 淡入，见文件头说明）----

        QoolControl {
            //TODO: 在Example中应该实现一种基于QSettings的持久化，保证ExampleApp本身可以色彩存储持久化，同时此代码的将起到示例作用
            title: qsTr("调色板")
            contentItem: ColorBankPanel {
                colorAssistant: mainColor
            }
            QoolTip {
                text: qsTr("S 存入当前颜色，L 载入槽位颜色；显示 24 格，存储不设上限")
                color: Style.yellow
            }
        }
    } //cc
}
