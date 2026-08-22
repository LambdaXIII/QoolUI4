// Playground：测试场——Qool.Controls 控件的调试用例（仓库开发模式：
// 可随意更改，不保留旧内容）。
//
// 当前含 HSV/HSL 面板 + 竖直通道滑块调试用例：
// - HSV 色轮面板（HSVPanel）与 HSL 面板（HSLPanel）共享 mainColor——
//   双向联动（面板改色、picker 取色三路同步，同值收敛无环）。
// - ColorChannelVerticalSlider 竖直通道滑块演示（HSVHue/HSVSaturation/
//   HSVValue 三通道，绑定共享 mainColor）——拖动/点击跳转/键盘步进/
//   justMoved 手感人工验收（hue 通道彩虹原理式跟随当前 sat/value）。
import QtQuick
import Qool
import Qool.Controls
import Qool.Color
import Qool.Debug
import QtQuick.Layouts

BasicPage {
    id: root

    title: qsTr("测试场")
    note: qsTr("调试用例（ColorChannelSlider 通道滑块调试中）")

    // 共享色源：与 picker 无条件双向同步（同值守卫收敛——见文件头）
    ColorAssistant {
        id: mainColor
    }

    QoolControl {
        x: 30
        title: qsTr("HSV色轮面板")
        contentItem: HSVPanel {
            id: hsvPanel
            colorAssistant: mainColor
        }

        RectResizer {}
    }

    QoolControl {
        x: 200
        title: qsTr("HSL面板")
        contentItem: HSLPanel {
            id: hslPanel
            colorAssistant: mainColor
        }

        RectResizer {    }

    QoolControl {
        x: 380
        title: qsTr("竖直通道滑块")
        contentItem: Row {
            spacing: 8
            ColorChannelVerticalSlider {
                colorAssistant: mainColor
                channel: ColorNameHQ.HSVHue
                height: 150
            }
            ColorChannelVerticalSlider {
                colorAssistant: mainColor
                channel: ColorNameHQ.HSVSaturation
                height: 150
            }
            ColorChannelVerticalSlider {
                colorAssistant: mainColor
                channel: ColorNameHQ.HSVValue
                height: 150
            }
        }

        RectResizer {}
    }
    }
}
