import QtQuick
import Qool

Behavior {
    id: root

    /* 动画时长/缓动（默认 Style.transitionDuration / InOutQuad——
       对齐 BasicNumberBehavior） */
    property alias duration: ani.duration
    property alias easing: ani.easing

    enabled: targetProperty.object?.Style.animationEnabled ?? Style.animationEnabled

    /* 最近一次已知实际角度。Behavior 拦截属性变化时，目标属性仍保持
       旧值（真属性由动画 job 写入）——经 targetValueChanged（每次拦截
       前同步发出）读取，得动画准确起点（旧值或动画中间值）。 */
    property real lastValue: 0

    onTargetValueChanged: {
        root.lastValue = Number(root.targetProperty.object[root.targetProperty.name])
    }

    /* 最近路径：把目标角度归一化到离起点最近的等价角（±180° 内） */
    function nearest(current, target) {
        const delta = ((target - current + 180) % 360 + 360) % 360 - 180
        return current + delta
    }

    SequentialAnimation {
        NumberAnimation {
            id: ani
            from: root.lastValue
            to: root.nearest(root.lastValue, root.targetValue)
            duration: Style.transitionDuration
            easing.type: Easing.InOutQuad
        }
        // 动画到达等价角（视觉 = 目标角）后，PropertyAction 把受控属性
        // 写回真实目标值——静默跳回（视觉无变化），属性读数干净
        PropertyAction { }
    }
}
