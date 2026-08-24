import QtQuick
import Qool

// 通道数值文本（拍平件，置于 _private——暂不耦合 Controls）：
// ColorChannelEdit 的通道标签（Tag）与数值显示（displayItem）的统一文本
// 组件——字体来源统一为 PixelFont.normal（MozartNBP 24px），标签/显示/
// 编辑层同一字体，避免漂移。颜色与对齐按用途覆盖（标签 Style.buttonText
// 右对齐贴数值、数值显示 Style.text）。
Text {
    id: root

    font: PixelFont.normal
    color: Style.text
    horizontalAlignment: Text.AlignRight
    verticalAlignment: Text.AlignVCenter

    // 透明即隐藏（EditableText 显示层隐藏机制——编辑态 opacity 0 时不
    // 占事件；标签用法 opacity 恒 1 无影响）
    visible: opacity > 0
}
