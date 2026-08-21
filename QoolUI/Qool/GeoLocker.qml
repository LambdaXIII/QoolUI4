import QtQuick
import Qool

// 几何锁定器（SmartObject——非 Item 容器，无渲染）：把 target 的
// x/y/width/height 锁定跟随 lockTo——四维度独立开关 + 总开关。
// 典型用途：覆盖层/装饰层对齐到目标项（同父对齐场景）。target 与
// lockTo 可为任何带 x/y/width/height 四个属性的对象（Item/QtObject
// 自定义属性均可）。
//
// 坐标系提醒（重要）：x/y 是 lockTo 在**其父级坐标系**中的坐标——target
// 与 lockTo 同父时语义直观（几何对齐）；跨父使用时锁定的是「lockTo 的
// 父级坐标值」，不是 target 父级坐标系下的相对位置——跨父对齐需宿主
// 自行换算（mapToItem）后再设置 target 坐标。
//
// 开关语义：关闭 = 解除该维度锁定（绑定不活跃，target 该维度自由，保持
// 最后值）；重开 = 恢复锁定（跟随 lockTo 当前值/下次变化）。
SmartObject {
    id: root

    property bool enabled: true
    property bool xEnabled: true
    property bool yEnabled: true
    property bool widthEnabled: true
    property bool heightEnabled: true

    // 对象引用类型（QtObject 而非 var）：Binding target 必须可走
    // QQmlProperty（QObject）——var 的宽松是伪收益（纯 JS 对象绑定不了），
    // QtObject 带类型检查且语义明确（对象引用）。
    property QtObject target
    property QtObject lockTo

    Binding {
        target: root.target
        property: "x"
        value: root.lockTo.x //FIXME:假定了lockTo一定有x且可绑定
        when: root.enabled && root.xEnabled && root.target && root.lockTo
    }
    Binding {
        target: root.target
        property: "y"
        value: root.lockTo.y
        when: root.enabled && root.yEnabled && root.target && root.lockTo
    }
    Binding {
        target: root.target
        property: "width"
        value: root.lockTo.width
        when: root.enabled && root.widthEnabled && root.target && root.lockTo
    }
    Binding {
        target: root.target
        property: "height"
        value: root.lockTo.height
        when: root.enabled && root.heightEnabled && root.target && root.lockTo
    }
}
