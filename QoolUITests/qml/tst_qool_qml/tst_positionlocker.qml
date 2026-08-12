import QtQuick
import QtTest
import Qool

// PositionLocker 行为测试（Qool/PositionLocker.qml）
//
// 被测契约：
// - target 被绑定锁定到 lockTo 的锚点（默认 TopLeft/TopLeft 对齐）
// - targetAnchorPosition / lockToAnchorPosition 组合驱动偏移
// - horizontalSpacing / verticalSpacing 带符号间距（方向由相对位置决定）
// - xOffset / yOffset 直接追加偏移
// - autoLock / enabled 关闭时绑定失效（target 不再被覆盖）
// - lockTo 动态移动时 target 跟随
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（状态隔离规范），
// 时序/异步断言一律 tryCompare 轮询。
//
// QML 测试注意：id 不是对象属性——场景子对象经 property alias 暴露
// （scene.lockerRef 等）；PositionLocker 属性名与场景 id 不能同名
// （lockTo: lockTo 会自引用），场景内 id 用 lockToItem/targetItem。

TestCase {
    id: root

    name: "PositionLocker"
    width: 300
    height: 300

    Component {
        id: sceneComp
        Item {
            id: axis
            width: 200
            height: 200

            property alias lockerRef: locker
            property alias lockToRef: lockToItem
            property alias targetRef: targetItem

            // lockTo：宽 100 高 80，位于 axis 内 (50, 40)
            Item {
                id: lockToItem
                width: 100
                height: 80
                x: 50
                y: 40
            }

            // target：被锁定对象，初始无显式位置（由 locker 接管）
            Item {
                id: targetItem
            }

            PositionLocker {
                id: locker
                axisItem: axis
                lockTo: lockToItem
                target: targetItem
            }
        }
    }

    function makeScene() {
        return createTemporaryObject(sceneComp, root)
    }

    function test_topLeftAlignmentDefault() {
        const scene = makeScene()
        // 默认锚点：target 左上角对齐 lockTo 左上角
        tryCompare(scene.targetRef, "x", 50, 1000)
        tryCompare(scene.targetRef, "y", 40, 1000)
    }

    function test_anchorCombination() {
        const scene = makeScene()
        // lockTo 锚点右下角：basePos = (150, 120)
        scene.lockerRef.lockToAnchorPosition = Qore.BottomRight
        tryCompare(scene.targetRef, "x", 150, 1000)
        tryCompare(scene.targetRef, "y", 120, 1000)

        // target 锚点右下角：targetMovement = (-w, -h)；target 默认 0 宽高
        // （BottomRight 锚点无偏移），显式设置尺寸后回到 (50, 40)
        scene.targetRef.width = 100
        scene.targetRef.height = 80
        scene.lockerRef.targetAnchorPosition = Qore.BottomRight
        tryCompare(scene.targetRef, "x", 50, 1000)
        tryCompare(scene.targetRef, "y", 40, 1000)
    }

    function test_targetSizeAffectsAnchor() {
        const scene = makeScene()
        // target 尺寸参与偏移：BottomRight 锚点 → targetMovement = (-w, -h)
        scene.targetRef.width = 40
        scene.targetRef.height = 30
        scene.lockerRef.targetAnchorPosition = Qore.BottomRight
        tryCompare(scene.targetRef, "x", 50 - 40, 1000)
        tryCompare(scene.targetRef, "y", 40 - 30, 1000)
    }

    function test_spacingPositiveDirection() {
        const scene = makeScene()
        // lockTo 在 target 右下方（basePos 正）→ 正间距向外推
        scene.lockerRef.horizontalSpacing = 10
        scene.lockerRef.verticalSpacing = 5
        tryCompare(scene.targetRef, "x", 50 + 10, 1000)
        tryCompare(scene.targetRef, "y", 40 + 5, 1000)
    }

    function test_spacingNegativeDirection() {
        const scene = makeScene()
        // lockTo 移到 target 左上方（basePos 负）→ 正间距反向推
        scene.lockToRef.x = -50
        scene.lockToRef.y = -40
        scene.lockerRef.horizontalSpacing = 10
        scene.lockerRef.verticalSpacing = 5
        tryCompare(scene.targetRef, "x", -50 - 10, 1000)
        tryCompare(scene.targetRef, "y", -40 - 5, 1000)
    }

    function test_offsets() {
        const scene = makeScene()
        scene.lockerRef.xOffset = 5
        scene.lockerRef.yOffset = -5
        tryCompare(scene.targetRef, "x", 50 + 5, 1000)
        tryCompare(scene.targetRef, "y", 40 - 5, 1000)
    }

    function test_autoLockDisabled() {
        const scene = makeScene()
        scene.lockerRef.autoLock = false
        scene.targetRef.x = 100
        scene.targetRef.y = 100
        // 移动 lockTo：若绑定仍生效 target 会被覆盖为 (80, 40)
        scene.lockToRef.x = 80
        wait(100) // 给潜在绑定一帧求值窗口（负向断言：验证不跟随）
        compare(scene.targetRef.x, 100)
        compare(scene.targetRef.y, 100)
    }

    function test_enabledDisabled() {
        const scene = makeScene()
        scene.lockerRef.enabled = false
        scene.targetRef.x = 7
        scene.targetRef.y = 9
        scene.lockToRef.x = 80
        wait(100)
        compare(scene.targetRef.x, 7)
        compare(scene.targetRef.y, 9)
    }

    function test_dynamicFollow() {
        const scene = makeScene()
        scene.lockToRef.x = 80
        scene.lockToRef.y = 10
        tryCompare(scene.targetRef, "x", 80, 1000)
        tryCompare(scene.targetRef, "y", 10, 1000)
    }
}
