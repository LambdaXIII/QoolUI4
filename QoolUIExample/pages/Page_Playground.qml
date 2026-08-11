// Playground：测试场——Qool.Controls 控件的调试用例（仓库开发模式：
// 可随意更改，不保留旧内容）。
//
// 当前为空（2026-08-11：EditableText 密码回显调试用例已迁移
// Page_InputControls 正式展示页；本页保留供后续调试使用）。
import QtQuick
import Qool
import Qool.Controls
import Qool.Debug

BasicPage {
    id: root

    title: qsTr("测试场")
    note: qsTr("调试用例（当前为空）")

    Dial {
        RectResizer {}
    }
}
