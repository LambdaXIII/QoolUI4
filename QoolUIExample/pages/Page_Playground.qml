// Playground：测试场——Qool.Controls 控件的调试用例（仓库开发模式：
// 可随意更改，不保留旧内容）。
//
// 当前含 RangeSlider 调试用例（RangeSlider + RectResizer——区间滑块
// 三层结构的几何/交互调试场）。
import QtQuick
import Qool
import Qool.Controls
import Qool.Debug
import QtQuick.Layouts

BasicPage {
    id: root

    title: qsTr("测试场")
    note: qsTr("调试用例（RangeSlider 调试中）")

    RangeSlider {
        x: 30
        y: 30
        width: 200
        RectResizer {}
    }
}
