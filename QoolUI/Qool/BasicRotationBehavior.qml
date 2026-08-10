import QtQuick
import Qool

/*!
    \qmltype BasicRotationBehavior
    \inqmlmodule Qool
    \brief 角度属性 Behavior——旋转动画沿最近路径过渡（等价角判定）。

    BasicRotationBehavior 是 \l Behavior 的专门化，用于**角度类数值属性**
    （如 \c rotation）：属性变化时动画不沿直线插值，而是取离当前值
    最近的等价角作为动画目标——例如从 270° 变到 0° 时实际走
    270°→360°（顺时针 90°），到达后瞬间回到真实目标值 0°（视觉无
    变化——静默跳回），避免逆时针 270° 的大圈旋转。

    动画中途目标再次变化时，动画从当前中间角度继续沿最近路径过渡
    （无跳变）。宿主用法与 \l BasicNumberBehavior 相同：

    \qml
    Item {
        property int direction: Qore.E
        rotation: direction === Qore.E ? 225 : 0
        BasicRotationBehavior on rotation {
            enabled: root.Style.animationEnabled
            duration: root.Style.movementDuration
        }
    }
    \endqml

    \note 仅适用于角度语义的属性（值按 360° 周期等价）——对普通数值
    属性使用会把目标值归一化到起点 ±180° 邻域，行为错误。

    \section1 属性文档

    \qmlproperty real BasicRotationBehavior::duration
    动画时长（毫秒）——默认 \l Style 的 \c transitionDuration。

    \qmlproperty group BasicRotationBehavior::easing
    \qmlproperty enumeration BasicRotationBehavior::easing.type
    缓动曲线——默认 \c Easing.InOutQuad。

    \qmlproperty bool BasicRotationBehavior::enabled
    动画开关——默认 \l Style 的 \c animationEnabled（目标属性对象不可用时
    回退同值）；宿主可覆写。
*/
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
