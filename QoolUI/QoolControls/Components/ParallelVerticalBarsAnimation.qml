import QtQuick
import Qool

// 注：勿 import QtQuick.Controls——本文件不使用任何 Controls 类型；冗余
// import 会在运行时拉起样式插件依赖链（Fusion/Windows），QML 测试通道
// 无 Qt bin PATH 时直接加载失败（tst_dialogbutton 实案）。

NumberAnimation {
    id: root

    readonly property ParallelVerticalBars targetBars: target as ParallelVerticalBars

    property real offsetStart: 0
    property real offsetMove: targetBars.barOffset

    duration: Style.movementDuration * 5
    property: "offset"

    from: offsetStart
    to: offsetStart + (offsetMove - offsetMove / duration)
    loops: Animation.Infinite

    running: true
}
