// Playground：测试场——Qool.Controls 控件的调试用例（仓库开发模式：
// 可随意更改，不保留旧内容）。
//
// 当前含 ColorChannelSlider 调试用例（三通道滑块 + 编辑配对 + 取色器
// 双向联动）：
// - 反向绑定修复（缺陷根源——旧 `colorAssistant.color: picker.currentColor`
//   单向绑定：编辑/拖动通道改色后被绑定回写覆盖、编辑效果回滚、picker
//   永不回显新色）。改为无条件双向同步（picker 取色写 assistant、
//   assistant 变色回写 picker）——同值收敛实证（assistant 相等守卫 +
//   QML 值类型同值不触发），无环无抖动。
// - 三通道 ColorChannelSlider 与既有 ColorChannelEdit 同 colorAssistant
//   同 channel 配对——拖动/编辑/picker 取色三路联动演示。
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
        id: ca

        // 读方向：assistant 变色（滑块/编辑写链、外部程序）→ picker 回显
        onColorChanged: picker.currentColor = ca.color
    }

    Column {
        // 取色方向：picker 取色 → assistant（写链）
        ColorQuickPicker {
            id: picker
            defaultColor: "red"
            onCurrentColorChanged: ca.color = picker.currentColor
        }

        // 三通道滑块 + 编辑配对（同 assistant 同 channel——拖动/编辑双向
        // 联动；与 picker 经 ca 全链闭合）
        ColorChannelControl {
            colorAssistant: ca
            channel: ColorNameHQ.HSVHue
        }

        ColorChannelControl {
            colorAssistant: ca
            channel: ColorNameHQ.HSVSaturation
        }

        ColorChannelControl {
            colorAssistant: ca
            channel: ColorNameHQ.HSVValue
        }
    }
}
