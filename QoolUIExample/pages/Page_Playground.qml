// Playground：测试场——Qool.Controls 控件的调试用例（仓库开发模式：
// 可随意更改，不保留旧内容）。
//
// 当前用途：通道族子元素独立呈现检查——7 个控件全部绑定同一共享
// ColorAssistant（mainColor），任意一处改值全体联动收敛：
// - ColorChannelSlider ×2（横 / 竖）
// - ColorChannelVerticalSlider ×2（横 / 竖——组件名只是历史名，
//   实为 T.Slider 双形态）
// - ColorChannelEdit ×3（横 / 竖 / 竖镜像）
// 每个 QoolControl 包裹单个控件，便于观察占位范围。
import QtQuick
import Qool
import Qool.Controls
import Qool.Color

BasicPage {
    id: root

    title: qsTr("测试场")
    note: qsTr("子元素独立呈现：Slider×2 + VerticalSlider×2 + Edit×3 共享同一 Assistant")

    // 共享色源：本页唯一 Assistant，全部子控件绑定它
    ColorAssistant {
        id: mainColor
        color: Style.accent
    }

    Column {
        spacing: 18

        // ---- 滑块行：两族各一横一竖 ----
        Row {
            spacing: 14

            QoolControl {
                title: qsTr("Slider 横")
                contentItem: ColorChannelSlider {
                    colorAssistant: mainColor
                    channel: ColorNameHQ.HSLHue
                }
            }
            QoolControl {
                title: qsTr("Slider 竖")
                contentItem: ColorChannelSlider {
                    colorAssistant: mainColor
                    channel: ColorNameHQ.Red
                    orientation: Qt.Vertical
                    implicitHeight: 160
                }
            }
            QoolControl {
                title: qsTr("VSlider 横")
                contentItem: ColorChannelVerticalSlider {
                    colorAssistant: mainColor
                    channel: ColorNameHQ.HSVValue
                    orientation: Qt.Horizontal
                }
            }
            QoolControl {
                title: qsTr("VSlider 竖")
                contentItem: ColorChannelVerticalSlider {
                    colorAssistant: mainColor
                    channel: ColorNameHQ.HSVHue
                    implicitHeight: 160
                }
            }
        }

        // ---- 编辑行：横 / 竖 / 竖镜像 三态 ----
        Row {
            spacing: 14

            QoolControl {
                title: qsTr("Edit 横")
                contentItem: ColorChannelEdit {
                    width: 220
                    colorAssistant: mainColor
                    channel: ColorNameHQ.Green
                }
            }
            QoolControl {
                title: qsTr("Edit 竖")
                contentItem: ColorChannelEdit {
                    width: 220
                    colorAssistant: mainColor
                    channel: ColorNameHQ.Blue
                    orientation: Qt.Vertical
                }
            }
            QoolControl {
                title: qsTr("Edit 竖镜像")
                contentItem: ColorChannelEdit {
                    width: 220
                    colorAssistant: mainColor
                    channel: ColorNameHQ.HSVValue
                    orientation: Qt.Vertical
                    tagOnTop: true
                }
            }
        }
    }
}
