import QtQuick
import QtTest
import Qool

// PositionTracker 行为契约测试（QML 面）
//
// 被测契约（docs/reference/Qool/PositionTracker.md）：
// - target 缺省 = 构造时父快照（QML 场景内 target 指向宿主场景）
// - point 是 target 局部坐标，scenePos 跟随祖先链变换
// - 无窗口时 globalPos == scenePos、currentWindow null
// - update() 强制立即重算
// - target null 透传：scenePos == globalPos == point
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（状态隔离规范）。
// 场景内 id 经 property alias 暴露。

TestCase {
    id: root

    name: "PositionTracker"
    width: 300
    height: 200

    function fuzzyEqPoint(a, b, eps) {
        return Math.abs(a.x - b.x) <= (eps === undefined ? 1e-6 : eps)
            && Math.abs(a.y - b.y) <= (eps === undefined ? 1e-6 : eps)
    }

    function makeSpy(target, signalName) {
        const spy = Qt.createQmlObject("import QtTest; SignalSpy {}", root)
        spy.target = target
        spy.signalName = signalName
        return spy
    }

    Component {
        id: trackedComp
        Item {
            id: host
            width: 200
            height: 200

            property alias trackerRef: tracker

            Item {
                id: target
                x: 10
                y: 20
                width: 50
                height: 50
            }

            PositionTracker {
                id: tracker
                target: target
                point: Qt.point(1, 2)
            }
        }
    }

    Component {
        id: nullTargetComp
        Item {
            property alias trackerRef: tracker
            PositionTracker {
                id: tracker
                target: null
                point: Qt.point(3.5, -2.0)
            }
        }
    }

    function test_tracked_point_scenePos() {
        const scene = createTemporaryObject(trackedComp, root)
        scene.trackerRef.update()
        // target 局部 (1,2) + target 位置 (10,20) → scene (11,22)
        tryCompare(scene.trackerRef, "scenePos", Qt.point(11, 22), 1000)
    }

    function test_globalPos_withWindow() {
        const scene = createTemporaryObject(trackedComp, root)
        scene.trackerRef.update()
        // QML TestCase 运行在 QQuickView 内：有窗口 → currentWindow 非空
        verify(scene.trackerRef.currentWindow !== null)
        // globalPos 为真实屏幕坐标（独立于 scenePos 的坐标系）
        verify(scene.trackerRef.globalPos !== undefined)
    }

    function test_nullTarget_passthrough() {
        const scene = createTemporaryObject(nullTargetComp, root)
        scene.trackerRef.update()
        // 无坐标系可映射：scene = global = point
        verify(fuzzyEqPoint(scene.trackerRef.scenePos, Qt.point(3.5, -2.0)))
        verify(fuzzyEqPoint(scene.trackerRef.globalPos, Qt.point(3.5, -2.0)))
        compare(scene.trackerRef.currentWindow, null)
    }

    function test_pointChange_follows() {
        const scene = createTemporaryObject(trackedComp, root)
        scene.trackerRef.update()
        scene.trackerRef.point = Qt.point(2, 3)
        scene.trackerRef.update()
        tryCompare(scene.trackerRef, "scenePos", Qt.point(12, 23), 1000)
    }

    function test_update_forcedRecompute() {
        const scene = createTemporaryObject(trackedComp, root)
        // 直接改 target 位置 → update() 同步重算
        const t = scene.trackerRef.target
        t.x = 30
        scene.trackerRef.update()
        tryCompare(scene.trackerRef, "scenePos", Qt.point(31, 22), 1000)
    }

    function test_valueGuard_noSignalOnSame() {
        const scene = createTemporaryObject(trackedComp, root)
        scene.trackerRef.update()
        const spy = makeSpy(scene.trackerRef, "scenePosChanged")
        // 同值重算：值守卫不发
        scene.trackerRef.update()
        compare(spy.count, 0)
    }
}
