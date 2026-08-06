// Qool.Color 示例页（v3 Page_Color.qml 迁移）：一个共享 ColorAssistant
// （mainColor）驱动全页组件联动——快速取色（ColorQuickPicker）/快速输入
// （ColorEdit）/预览（ColorPreviewer）双向同步（v3 Connections 照迁），
// HSV/HSL/RGB/CMYK 四面板 + 色名列表 + 色银行共享同一实例，任何一处改色
// 全页联动。
//
// v4 组织：BasicPage + SectionBar 分段 + QoolTip 提示（v3 的 QoolPage/
// InfoBox/PageSeparateBar 为 v3 组件，v4 无——按 v4 惯例替代）。
//
// 刻意设计（QoolTip 布局，防误改）：
// - 宽度按 v4 页面风格（Page_Buttons 同款）：面板/控件回落自然宽度
//   （implicitWidth），仅 SectionBar 全宽（width: root.width）。迁移曾把
//   全部控件设为 width: root.width 填满——与 v4 其他页面不一致，已移除。
// - QoolTip 是 anchors.fill: parent 的悬停检测层（acceptedButtons: Qt.NoButton，
//   不拦截点击/拖动），经 GlobalChatRoom 驱动 QoolTipPanel 浮层动态显示。
// - 面板的 Item 包装层是 QoolTip 的锚点宿主（面板根是 ColumnLayout，
//   不能直接锚定 MouseArea）；QoolTip 的 z: -1 使面板自有悬停消费
//   （如 NumInput 的 IBeam 光标）优先。
// - ColorQuickPicker/ColorNameList/ColorBankPanel 的交互依赖悬停状态
//   （渐变显隐/列表下划线/L·S 淡入），QoolTip 挂在分区标题上、不覆盖组件区域。
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
        spacing: 15

        // ---- 快速取色 / 快速输入 / 预览 ----
        GridLayout {
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
                    picker.currentColor = mainColor.color;
                    editor.currentColor = mainColor.color;
                }
            }
        }

        SectionBar {
            width: root.width
        }

        // ---- HSV 面板 ----
        Item {
            width: hsvPanel.width
            height: hsvPanel.height
            HSVPanel {
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
        Item {
            width: hslPanel.width
            height: hslPanel.height
            HSLPanel {
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
        Item {
            width: rgbPanel.width
            height: rgbPanel.height
            RGBPanel {
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
        Item {
            width: cmykPanel.width
            height: cmykPanel.height
            CMYKPanel {
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
            // 专项注释（缺陷修复）：v3 示例页有 Layout.preferredHeight: 450，迁移
            // 静默丢失该实例侧尺寸注入（回落 implicitHeight 500）。v4 页容器是
            // Column（无 Layout 附加属性），以 height 直设等价。
            height: 450
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
            // 专项注释（缺陷修复）：v3 示例页有 columns: 4 + Layout.preferredHeight: 450，
            // 迁移静默丢失两处实例侧注入（回落默认 6 列、隐含高度约 172px：
            // 槽位压扁、行数少 2）。恢复 v3 装配。
            height: 450
            columns: 4
            colorAssistant: mainColor
        }
    } //cc
}
