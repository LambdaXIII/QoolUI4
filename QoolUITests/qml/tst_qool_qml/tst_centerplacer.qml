import QtQuick
import QtTest
import Qool

// CenterPlacer 行为测试（Qool/CenterPlacer.qml）
//
// 被测契约（docs/reference/Qool/CenterPlacer.md 为准绳）：
// - centerx/centery 与 target.x/y 双向等价（center = x + width/2）
// - 写 centerx/centery → 代理设 target.x/y（target 尺寸参与换算）
// - target x/y/width/height 变化 → center 自动更新（w-h 参与）
// - 双向同步无死循环（同值守卫断环——任意频繁读写稳定）
// - 任意带 x/y/width/height 的 QtObject 可挂（不依赖 Item/视觉）
// - target 为 null 安全（不崩、不写）
// - target 切换（开放接口）：运行中换挂载对象 → 从新 target 现读同步
//   （旧 center 不残留），后续双向继续工作；从 null 挂上同理
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（对齐
// tst_positionlocker 挂件测试模式）；时序/异步断言 tryCompare 轮询。

TestCase {
    id: root

    name: "CenterPlacer"
    width: 300
    height: 300

    Component {
        id: sceneComp
        Item {
            width: 200
            height: 200

            property alias placerRef: placer
            property alias targetRef: targetItem

            // target：被放置对象，初始 x/y 由 placer 接管
            Item {
                id: targetItem
                width: 40
                height: 30
            }

            CenterPlacer {
                id: placer
                target: targetItem
            }
        }
    }

    function makeScene() {
        return createTemporaryObject(sceneComp, root)
    }
    // QtObject target 场景（自定义 x/y/width/height 属性）
    Component {
        id: qtObjectSceneComp
        Item {
            width: 200
            height: 200

            property alias placerRef: placer
            property alias targetRef: targetObj

            QtObject {
                id: targetObj
                property real x: 10
                property real y: 20
                property real width: 50
                property real height: 40
            }

            CenterPlacer {
                id: placer
                target: targetObj
            }
        }
    }

    // target 为 null 场景（挂件空挂——安全契约）
    Component {
        id: nullTargetComp
        Item {
            width: 200
            height: 200

            property alias placerRef: placer

            CenterPlacer {
                id: placer
            }
        }
    }

    // —— 读方向：target 位置变化 → center 更新（含 w-h 参与）——
    function test_centerReflectsPosition() {
        const scene = makeScene()
        // 初始：x=0 y=0 w=40 h=30 → center = (20, 15)
        tryCompare(scene.placerRef, "centerx", 20, 1000)
        tryCompare(scene.placerRef, "centery", 15, 1000)
        // target 移动 → center 跟随
        scene.targetRef.x = 50
        scene.targetRef.y = 40
        tryCompare(scene.placerRef, "centerx", 70, 1000)
        tryCompare(scene.placerRef, "centery", 55, 1000)
    }

    // —— w-h 参与：target 尺寸变化 → center 更新（中心仍真实位置）——
    function test_sizeParticipates() {
        const scene = makeScene()
        scene.targetRef.x = 100
        scene.targetRef.y = 60
        tryCompare(scene.placerRef, "centerx", 120, 1000)
        scene.targetRef.width = 80
        scene.targetRef.height = 50
        // center = x + w/2 = 100 + 40 = 140；y + h/2 = 60 + 25 = 85
        tryCompare(scene.placerRef, "centerx", 140, 1000)
        tryCompare(scene.placerRef, "centery", 85, 1000)
    }

    // —— 写方向：写 center → 代理设 target.x/y ——
    function test_centerWritesPosition() {
        const scene = makeScene()
        scene.placerRef.centerx = 120
        scene.placerRef.centery = 80
        // target.x = centerx − w/2 = 120 − 20 = 100；y = 80 − 15 = 65
        tryCompare(scene.targetRef, "x", 100, 1000)
        tryCompare(scene.targetRef, "y", 65, 1000)
    }

    // —— 双向等价：读写 center ≡ 读写 x/y ——
    function test_bidirectionalEquivalence() {
        const scene = makeScene()
        // x/y → center
        scene.targetRef.x = 30
        scene.targetRef.y = 20
        tryCompare(scene.placerRef, "centerx", 50, 1000)
        tryCompare(scene.placerRef, "centery", 35, 1000)
        // center → x/y
        scene.placerRef.centerx = 90
        scene.placerRef.centery = 55
        tryCompare(scene.targetRef, "x", 70, 1000)
        tryCompare(scene.targetRef, "y", 40, 1000)
        // 往返后值稳定（无漂移）
        tryCompare(scene.placerRef, "centerx", 90, 1000)
        tryCompare(scene.placerRef, "centery", 55, 1000)
    }

    // —— 守卫断环：频繁往返读写稳定不抖动（无死循环风暴）——
    function test_noLoopStorm() {
        const scene = makeScene()
        // 连续交替写 center ↔ x：若成环会无限重入（信号风暴）；同值守卫
        // 断环——值稳定落定
        for (let i = 0; i < 50; ++i) {
            scene.placerRef.centerx = 100 + i
            scene.targetRef.x = 100 + i
        }
        tryCompare(scene.placerRef, "centerx", 169, 1000)
        // 同值写回：写 centerx 为当前 center → 不触发 x 写（无环）
        const before = scene.targetRef.x
        scene.placerRef.centerx = scene.placerRef.centerx
        wait(50)
        compare(scene.targetRef.x, before, "same-value center write -> no x write")
    }

    // —— 任意 target 对象：QtObject 带自定义 x/y/width/height ——
    function test_qtobjectTarget() {
        const scene = createTemporaryObject(qtObjectSceneComp, root, {})
        // QtObject 自定义属性：center = x + w/2 = 10 + 25 = 35
        tryCompare(scene.placerRef, "centerx", 35, 1000)
        tryCompare(scene.placerRef, "centery", 40, 1000)
        // 写 center → 代理写 QtObject 自定义 x/y
        scene.placerRef.centerx = 60
        tryCompare(scene.targetRef, "x", 35, 1000)
        // QtObject 属性变化 → center 跟随
        scene.targetRef.width = 100
        tryCompare(scene.placerRef, "centerx", 85, 1000)
    }

    // —— target 为 null：安全（不崩、不写）——
    function test_nullTargetSafe() {
        const scene = createTemporaryObject(nullTargetComp, root, {})
        scene.placerRef.centerx = 100
        scene.placerRef.centery = 100
        compare(scene.placerRef.centerx, 100, "center holds when target null")
    }

    // —— target 切换（开放接口）：运行中换挂载对象 → 从新 target 现读
    // 同步（旧 center 不残留），后续双向继续工作——
    function test_targetSwitch() {
        const scene = makeScene()
        // 初始挂 targetItem（x=0 w=40）→ center = (20, 15)
        tryCompare(scene.placerRef, "centerx", 20, 1000)
        // 新目标对象：不同位置/尺寸
        const newTarget = Qt.createQmlObject('import QtQuick; Item { x: 100; y: 50; width: 60; height: 40 }',
            scene, "newTarget")
        scene.placerRef.target = newTarget
        // 切换即现读：center = (100 + 30, 50 + 20) = (130, 70)
        tryCompare(scene.placerRef, "centerx", 130, 1000, "switch resyncs to new target")
        tryCompare(scene.placerRef, "centery", 70, 1000)
        // 新 target 变化 → center 继续跟随（Connections 已转移）
        newTarget.x = 200
        tryCompare(scene.placerRef, "centerx", 230, 1000, "follows new target")
        // 写 center → 写新 target.x/y
        scene.placerRef.centerx = 300
        tryCompare(newTarget, "x", 270, 1000, "writes new target")
        // 旧 target 不再被影响（已断开）
        const oldX = scene.targetRef.x
        scene.placerRef.centerx = 400
        tryCompare(newTarget, "x", 370, 1000)
        compare(scene.targetRef.x, oldX, "old target untouched after switch")
        // 切回 null：安全
        scene.placerRef.target = null
        compare(scene.placerRef.centerx, 400, "center holds when target null")
    }

    // —— target 从 null 挂上：现读同步（与创建时挂载等价）——
    function test_targetAttachFromNull() {
        const scene = createTemporaryObject(nullTargetComp, root, {})
        scene.placerRef.centerx = 999
        scene.placerRef.centery = 999
        // 挂上带值对象 → 立即现读（覆盖残留）
        const newTarget = Qt.createQmlObject('import QtQuick; Item { x: 10; y: 20; width: 40; height: 30 }',
            scene, "newTarget2")
        scene.placerRef.target = newTarget
        tryCompare(scene.placerRef, "centerx", 30, 1000, "attach resyncs from target")
        tryCompare(scene.placerRef, "centery", 35, 1000)
    }
}
