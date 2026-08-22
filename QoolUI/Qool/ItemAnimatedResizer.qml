import QtQuick
import Qool
import Qool.Controls

// ItemAnimatedResizer：resized 驱动的双向尺寸切换器（Qool 通用逻辑件——
// 非可视组件，无控件依赖）。用于「展开-收缩」类状态：resized 为 true 时
// 前进到 to 尺寸（展开）、false 时后退到 from 尺寸（收缩）——典型消费如
// RangeSlider 前景 hover/锁存展开、Slider 手柄常态/展开切换。
//
// 模型：resized 是方向开关（宿主绑定或赋值），from/to 是目标尺寸
// （fromWidth/fromHeight/toWidth/toHeight——绑定持续生效，目标跟随）；
// 方向切换时动画过渡（动画门控 animationEnabled，关闭即跳变）。
//
// enabled：门控 resized 响应——false 时 resized 变化被忽略、尺寸冻结在
// 当前值；用于宿主级禁用（控件 enabled 联动时前景/装饰应整体静止，
// 见 RangeSlider 中 enabled: root.enabled 的用法）。
//
// 动画模板：forewardAnimation/backwardAnimation（NumberAnimation alias）——
// 宿主可独立定制前进/后退的 easing 与 duration；两方向动画各自从模板取值。
//
// 锁机制：动画完成/跳变后锁定对应方向（Binding 将尺寸钉在目标值）——
// 锁定期内目标绑定变化实时跟随；动画运行时解锁（动画接管尺寸）。
//
// 初始就位：构造后按 resized 当前值跳变就位（first_time_ensure——不经
// 动画）。onResizedChanged 只在 resized 变化时触发，初始绑定求值
// resized=true 不触发，需显式就位；否则初始 resized=true 的消费方停在
// 收缩态，违反「resized 是方向开关」契约。

SmartObject {
    id: root
    property bool enabled: true
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    property alias forewardAnimation: templateFowardAni
    property alias backwardAnimation: templateBackwardAni

    property alias fromWidth: backGroup.width
    property alias fromHeight: backGroup.height
    property alias toWidth: foreGroup.width
    property alias toHeight: foreGroup.height

    property bool resized: false
    readonly property real width: pCtrl.width
    readonly property real height: pCtrl.height
    readonly property bool running: forewardAni.running || backwardAni.running

    NumberAnimation {
        id: templateFowardAni
        easing.type: Easing.OutCurve
        duration: Style.transitionDuration
    }

    NumberAnimation {
        id: templateBackwardAni
        easing.type: Easing.OutCurve
        duration: Style.transitionDuration
    }

    QtObject {
        id: backGroup
        property real width: 100
        property real height: 100

        readonly property bool reached: width === pCtrl.width && height === pCtrl.height
    }

    QtObject {
        id: foreGroup
        property real width: 120
        property real height: 120

        readonly property bool reached: width === pCtrl.width && height === pCtrl.height
    }

    ParallelAnimation {
        id: forewardAni
        NumberAnimation {
            target: pCtrl
            property: "width"
            to: foreGroup.width
            easing: templateFowardAni.easing
            duration: templateFowardAni.duration
        }
        NumberAnimation {
            target: pCtrl
            property: "height"
            to: foreGroup.height
            easing: templateFowardAni.easing
            duration: templateFowardAni.duration
        }
        onStarted: pCtrl.unlock()
        onFinished: pCtrl.lock_foreward()
    }

    // 后退动画——easing/duration 取 backwardAnimation 模板（与前进模板
    // 独立，宿主可分别定制两方向节奏）。
    ParallelAnimation {
        id: backwardAni
        NumberAnimation {
            target: pCtrl
            property: "width"
            to: backGroup.width
            easing: templateBackwardAni.easing
            duration: templateBackwardAni.duration
        }
        NumberAnimation {
            target: pCtrl
            property: "height"
            to: backGroup.height
            easing: templateBackwardAni.easing
            duration: templateBackwardAni.duration
        }
        onStarted: pCtrl.unlock()
        onFinished: pCtrl.lock_backward()
    }

    SmartObject {
        id: pCtrl
        property real width
        property real height

        // 方向锁：true 表示对应方向已就位（Binding 钉住尺寸、目标绑定
        // 实时跟随）；初始 backwardLocked——构造即收缩态。动画开始解锁、
        // 完成/跳变后锁回，保证「就位」状态由锁定 Binding 持续维持。
        property bool forewardLocked: false
        property bool backwardLocked: true

        function unlock() {
            forewardLocked = false;
            backwardLocked = false;
        }

        function lock_foreward() {
            forewardLocked = true;
            backwardLocked = false;
        }

        function lock_backward() {
            forewardLocked = false;
            backwardLocked = true;
        }

        function jump_foreward() {
            unlock();
            pCtrl.width = foreGroup.width;
            pCtrl.height = foreGroup.height;
            lock_foreward();
        }

        function jump_backward() {
            unlock();
            pCtrl.width = backGroup.width;
            pCtrl.height = backGroup.height;
            lock_backward();
        }

        function dive_foreward() {
            if (backwardAni.running)
                backwardAni.stop();
            forewardAni.restart();
        }

        function dive_backward() {
            if (forewardAni.running)
                forewardAni.stop();
            backwardAni.restart();
        }

        function go_foreward() {
            if (foreGroup.reached)
                return;
            if (root.animationEnabled && templateFowardAni.duration > 0)
                dive_foreward();
            else
                jump_foreward();
        }

        function go_backward() {
            if (backGroup.reached)
                return;
            if (root.animationEnabled && templateBackwardAni.duration > 0)
                dive_backward();
            else
                jump_backward();
        }

        // 状态变化过渡：resized 变化时按当前值前进/后退（动画路径——
        // 兼容中途打断：go_* 先检查 reached，动画运行时 dive_* 先 stop
        // 反向动画再 restart 本向）。
        function ensure() {
            if (root.resized)
                go_foreward();
            else
                go_backward();
        }

        // 初始就位：直接跳变到 resized 对应状态（不经动画——初始化无
        // 过渡；动画仅用于状态变化后的过渡，见 go_* / ensure）。
        function first_time_ensure() {
            if (root.resized)
                jump_foreward();
            else
                jump_backward();
        }

        Connections {
            enabled: root.enabled
            target: root
            function onResizedChanged() {
                pCtrl.ensure();
            }
        }
    }//pCtrl

    // 初始就位：构造后按 resized 当前值跳变就位。enabled=false 时与
    // 响应门控一致（冻结，不就位）。
    Component.onCompleted: {
        if (root.enabled)
            pCtrl.first_time_ensure();
    }

    // enabled 恢复（开放接口——宿主可随时切换）：false→true 时 resized
    // 若已处于目标值（禁用期间的变化被 Connections 忽略、尺寸冻结），
    // 恢复后不再有变化信号 → 不会自举。恢复即按当前 resized 就位一次
    // （动画路径——与正常状态变化一致；resized 未变时 go_* 的 reached
    // 检查使之为 no-op）。用 Connections 独立监听（非 onEnabledChanged
    // 直接 handler——后者可被外部实例覆盖）。
    Connections {
        target: root
        function onEnabledChanged() {
            if (root.enabled)
                pCtrl.ensure();
        }
    }

    // 锁定 Binding：方向锁定时把 pCtrl 尺寸钉在对应目标组——目标属性
    // （fromWidth 等）后续变化实时跟随（目标跟随契约）；动画运行时解锁
    // 释放给动画接管。四组（前进/后退 × 宽/高）同一机制。
    Binding {
        when: pCtrl.forewardLocked
        target: pCtrl
        property: "width"
        value: foreGroup.width
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: pCtrl.forewardLocked
        target: pCtrl
        property: "height"
        value: foreGroup.height
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: pCtrl.backwardLocked
        target: pCtrl
        property: "width"
        value: backGroup.width
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: pCtrl.backwardLocked
        target: pCtrl
        property: "height"
        value: backGroup.height
        restoreMode: Binding.RestoreNone
    }
}
