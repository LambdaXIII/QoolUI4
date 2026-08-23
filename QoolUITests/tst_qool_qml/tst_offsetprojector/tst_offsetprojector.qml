import QtQuick
import QtTest
import Qool

// OffsetProjector QML 冒烟（Qool/shapecontrol/qool_offsetprojector.cpp）
//
// 被测契约：
// - QML 可实例化；独立使用（不设任何属性）时 offset 恒零向量（默认自洽）
// - QML 绑定驱动：direction/refDistance 绑定外部属性 → 源变化 offset 自动
//   更新（NOTIFY 响应式）
// - 输出只读（offset 无写入口，赋值被忽略）
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（状态隔离规范）；
// 异步断言一律 tryCompare 轮询。

TestCase {
    id: root

    name: "OffsetProjector"

    Component {
        id: offsetComp
        OffsetProjector {
            direction: scene.direction
            refDirection: scene.refDirection
            refDistance: scene.refDistance
        }
    }

    Item {
        id: scene
        property var direction: Qt.vector2d(1, 0)
        property var refDirection: Qt.vector2d(1, 0)
        property real refDistance: 0
    }

    function fuzzyVector(v, x, y, tol) {
        return Math.abs(v.x - x) <= tol && Math.abs(v.y - y) <= tol
    }

    function resetScene() {
        // 场景为共享对象（TestCase 子对象）——每个测试函数开头重置，
        // 防状态泄漏（tst_cutsizebinding 同款隔离约定）
        scene.direction = Qt.vector2d(1, 0)
        scene.refDirection = Qt.vector2d(1, 0)
        scene.refDistance = 0
    }

    function test_instantiates() {
        resetScene()
        const p = createTemporaryObject(offsetComp, root)
        verify(p !== null)
        // 独立使用默认自洽：refDistance=0 → offset 零向量
        verify(fuzzyVector(p.offset, 0, 0, 0.0001))
    }

    function test_bindingDirectionUpdates() {
        // QML 绑定 direction → 源变化 offset 自动更新
        resetScene()
        const p = createTemporaryObject(offsetComp, root)
        scene.refDistance = 10
        tryCompare(p, "offset", Qt.vector2d(10, 0), 1000)
        scene.direction = Qt.vector2d(1, 1)
        tryCompare(p, "offset", Qt.vector2d(10, 10), 1000)
        // 正交方向对 → 退化 → offset 零向量（绑定路径的退化契约）
        scene.direction = Qt.vector2d(0, 1)
        tryCompare(p, "offset", Qt.vector2d(0, 0), 1000)
    }

    function test_bindingRefDistanceUpdates() {
        // QML 绑定 refDistance → 源变化 offset 自动更新
        resetScene()
        const p = createTemporaryObject(offsetComp, root)
        scene.refDistance = 5
        tryCompare(p, "offset", Qt.vector2d(5, 0), 1000)
        scene.refDistance = 0
        tryCompare(p, "offset", Qt.vector2d(0, 0), 1000)
        scene.refDistance = 7
        tryCompare(p, "offset", Qt.vector2d(7, 0), 1000)
    }

    function test_shortCircuitZeroDistance() {
        // refDistance=0 时方向变化不传播（绑定链下游无假更新）
        resetScene()
        const p = createTemporaryObject(offsetComp, root)
        scene.refDistance = 0
        scene.direction = Qt.vector2d(1, 1)
        wait(100) // 负向断言：结果恒零向量，offset 不变化
        verify(fuzzyVector(p.offset, 0, 0, 0.0001))
        // 恢复非零 → 链条自动恢复
        scene.refDistance = 3
        tryCompare(p, "offset", Qt.vector2d(3, 3), 1000)
    }
}
