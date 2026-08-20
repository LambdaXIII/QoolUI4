import QtQuick
import QtTest
import Qool

// CutSizesLocker QML 冒烟（Qool/shapecontrol/qool_qoolboxcutsizeslocker.cpp）
//
// 被测契约（core 层 C++ 直测为主，本层只覆盖注册与绑定面）：
// - QML 可实例化；默认 enabled=true、cutSize=0、target=null
// - target/cutSize 经 QML 绑定驱动后，cutSize 变化 → 四角同步
// - enabled 期外部直接改 target 任一角 → 其余三角联动统一
// - enabled=false → 四角恢复锁定前快照
// - target 为 null 时启用/设置 cutSize 空转不崩溃
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（状态隔离规范）；
// 时序/异步断言一律 tryCompare 轮询。

TestCase {
    id: root

    name: "CutSizesLocker"

    Component {
        id: lockerComp
        CutSizesLocker {}
    }

    Component {
        id: sceneComp
        Item {
            property real cutSizeValue: 10
            property alias settingsRef: settings
            property alias lockerRef: locker

            QoolBoxSettings {
                id: settings
                cutSizeTL: 1
                cutSizeTR: 2
                cutSizeBL: 3
                cutSizeBR: 4
            }

            CutSizesLocker {
                id: locker
                target: settings
                cutSize: cutSizeValue
                enabled: true
            }
        }
    }

    function makeScene() {
        return createTemporaryObject(sceneComp, root)
    }

    function fuzzyEq(actual, expected, tol) {
        return Math.abs(actual - expected) <= (tol !== undefined ? tol : 0.0001)
    }

    function verifyCorners(settings, tl, tr, bl, br) {
        return fuzzyEq(settings.cutSizeTL, tl)
            && fuzzyEq(settings.cutSizeTR, tr)
            && fuzzyEq(settings.cutSizeBL, bl)
            && fuzzyEq(settings.cutSizeBR, br)
    }

    function test_instantiatesWithoutTarget() {
        const locker = createTemporaryObject(lockerComp, root)
        verify(locker !== null)
        compare(locker.enabled, true)
        verify(fuzzyEq(locker.cutSize, 0))
        verify(locker.target === null)
        // target 为 null 时启用/设置 cutSize 空转不崩溃
        locker.cutSize = 5
        compare(locker.cutSize, 5)
        locker.enabled = false
        locker.enabled = true
    }

    function test_cutSizeBindingDrivesCorners() {
        const scene = makeScene()
        tryCompare(scene.settingsRef, "cutSizeTL", 10, 1000)
        tryCompare(scene.settingsRef, "cutSizeTR", 10, 1000)
        tryCompare(scene.settingsRef, "cutSizeBL", 10, 1000)
        tryCompare(scene.settingsRef, "cutSizeBR", 10, 1000)

        // 绑定源变化 → cutSize 更新 → 四角跟随
        scene.cutSizeValue = 20
        tryCompare(scene.settingsRef, "cutSizeTL", 20, 1000)
        tryCompare(scene.settingsRef, "cutSizeTR", 20, 1000)
        tryCompare(scene.settingsRef, "cutSizeBL", 20, 1000)
        tryCompare(scene.settingsRef, "cutSizeBR", 20, 1000)
    }

    function test_singleCornerChangeUnifiesOthers() {
        const scene = makeScene()
        tryCompare(scene.settingsRef, "cutSizeTL", 10, 1000)

        scene.settingsRef.cutSizeTR = 35
        tryCompare(scene.lockerRef, "cutSize", 35, 1000)
        tryCompare(scene.settingsRef, "cutSizeTL", 35, 1000)
        tryCompare(scene.settingsRef, "cutSizeTR", 35, 1000)
        tryCompare(scene.settingsRef, "cutSizeBL", 35, 1000)
        tryCompare(scene.settingsRef, "cutSizeBR", 35, 1000)
    }

    function test_disableRestoresSnapshot() {
        const scene = makeScene()
        tryCompare(scene.settingsRef, "cutSizeTL", 10, 1000)
        tryCompare(scene.settingsRef, "cutSizeTR", 10, 1000)

        scene.lockerRef.enabled = false
        tryCompare(scene.settingsRef, "cutSizeTL", 1, 1000)
        tryCompare(scene.settingsRef, "cutSizeTR", 2, 1000)
        tryCompare(scene.settingsRef, "cutSizeBL", 3, 1000)
        tryCompare(scene.settingsRef, "cutSizeBR", 4, 1000)
    }
}
