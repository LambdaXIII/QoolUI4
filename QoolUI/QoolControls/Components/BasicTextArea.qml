import QtQuick
import QtQuick.Controls as QC

import Qool

// **主题化默认 TextArea**（标准行为 + Qool 主题）

QC.TextArea {
    id: root

    color: Style.text
    selectionColor: Style.highlight
    selectedTextColor: Style.highlightedText

    font.pixelSize: Style.controlTextSize

    // 无背景（透明契约）：QC.TextArea 的 Basic 样式默认背景与本类型冲突——显式压掉
    background: null

    wrapMode: TextEdit.Wrap
    verticalAlignment: Text.AlignTop
}
