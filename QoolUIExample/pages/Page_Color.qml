// Qool.Color 示例页（v3 Page_Color.qml 迁移）：一个共享 ColorAssistant
// （mainColor）驱动全页组件联动——快速取色（ColorQuickPicker）/快速输入
// （ColorEdit）/预览（ColorPreviewer）双向同步（v3 Connections 照迁），
// HSV/HSL/RGB/CMYK 四面板 + 色名列表 + 色银行共享同一实例，任何一处改色
// 全页联动。
//
// v4 组织：BasicPage + SectionBar 分段 + QoolTip 提示（v3 的 QoolPage/
// InfoBox/PageSeparateBar 为 v3 组件，v4 无——按 v4 惯例替代）。
//
// 刻意设计（提示布局，防误改）：
// - 四面板交互面均为未开 hoverEnabled 的 InteractingArea（无悬停消费），
//   覆盖式 QoolTip 不影响拖动/双击重置/输入（QoolTip 接受 Qt.NoButton，
//   事件穿透）。面板根是 ColumnLayout，锚定子项受布局管理（不确定语义），
//   故 QoolTip 放在同尺寸 Item 包装层、z: -1：面板自有悬停消费（NumInput
//   的 IBeam HoverHandler）优先，其余区域提示生效。
// - ColorQuickPicker/ColorNameList/ColorBankPanel 的交互依赖悬停状态
//   （渐变显隐/列表下划线/L·S 淡入），满覆盖 QoolTip 会遮蔽悬停——
//   这三处提示挂在分区标题上，组件交互零干扰（v3 InfoBox 的 hover 提示
//   语义等价迁移）。
// - ColorEdit/ColorPreviewer 根为 Item 且无悬停消费组件，QoolTip 直接内嵌。
//
// 默认色：Component.onCompleted 赋 Style.highlight（v3 照迁）——此时
// Connections 已就位，picker/editor 首次即与面板同步为高亮色（若改为
// 声明期赋值，colorChanged 早于 Connections 创建，picker/editor 会滞留
// 默认白）。
//
// 不含颜色 Dialog 示范（v4 暂无 Dialog 模块，见 color-migration-spec §2.5）。
import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Color
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
        // width: root.width
        spacing: 15

        // ---- 快速取色 / 快速输入 / 预览 ----
        GridLayout {
            width: root.width
            columns: 2
            columnSpacing: 10
            rowSpacing: 15

            Text {
                text: qsTr("快速选取颜色")
                font: PixelFont.normal
                color: Style.text
                Layout.alignment: Qt.AlignTop
            }

            ColorQuickPicker {
                id: picker
                Layout.fillWidth: true
                onCurrentColorChanged: mainColor.color = currentColor
            }

            Text {
                text: qsTr("快速输入颜色")
                font: PixelFont.normal
                color: Style.text
                Layout.alignment: Qt.AlignTop
            }

            ColorEdit {
                id: editor
                Layout.fillWidth: true
                onCurrentColorChanged: mainColor.color = currentColor
                QoolTip {
                    text: qsTr("点击进入编辑，输入颜色名或 #RRGGBB / #AARRGGBB，回车或失焦提交")
                    color: Style.cyan
                }
            }

            ColorPreviewer {
                id: previewer
                colorAssistant: mainColor
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.preferredHeight: 80
                QoolTip {
                    text: qsTr("悬停此处显示提示：快速取色/快速输入与下方全部面板共享当前颜色，任意一处修改全页联动")
                    color: Style.cyan
                }
            }

            // picker/editor → mainColor 上行；mainColor → 下行回写（v3 照迁）。
            Connections {
                target: mainColor
                function onColorChanged() {
                    picker.currentColor = mainColor.color
                    editor.currentColor = mainColor.color
                }
            }
        }

        SectionBar {
            width: root.width
        }

        // ---- HSV 面板 ----
        Item {
            width: root.width
            height: hsvPanel.height
            HSVPanel {
                id: hsvPanel
                width: parent.width
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
        Item {
            width: root.width
            height: hslPanel.height
            HSLPanel {
                id: hslPanel
                width: parent.width
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
        Item {
            width: root.width
            height: rgbPanel.height
            RGBPanel {
                id: rgbPanel
                width: parent.width
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
        Item {
            width: root.width
            height: cmykPanel.height
            CMYKPanel {
                id: cmykPanel
                width: parent.width
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
        Text {
            text: qsTr("色名列表")
            font: PixelFont.normal
            color: Style.text
            QoolTip {
                text: qsTr("按分类浏览颜色名，点选色名即应用到当前颜色")
                color: Style.green
            }
        }

        ColorNameList {
            width: root.width
            colorAssistant: mainColor
        }

        SectionBar {
            width: root.width
        }

        // ---- 色银行（提示挂分区标题：槽位悬停驱动 L/S 淡入，见文件头说明）----
        Text {
            text: qsTr("色银行")
            font: PixelFont.normal
            color: Style.text
            QoolTip {
                text: qsTr("S 存入当前颜色，L 载入槽位颜色；显示 24 格，存储不设上限")
                color: Style.yellow
            }
        }

        ColorBankPanel {
            width: root.width
            colorAssistant: mainColor
        }
    } //cc
}
