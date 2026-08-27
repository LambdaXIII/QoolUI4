import QtQuick
import QtTest
import Qool

// ItemTracker 行为契约测试（QML 面）
//
// 被测契约（docs/reference/Qool/ItemTracker.md）：
// - target 任意 QObject：item 祖先查找、window 回退
// - itemEnabled：有效 enabled（含祖先链合取）；无 item 视为 true
// - windowActived：窗口激活态；无窗口视为 true
// - enabled 链变化 → itemEnabled 跟随（flow-on 监听）
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（状态隔离规范）。

TestCase {
    id: root

    name: "ItemTracker"
    width: 300
    height: 200

    Component {
        id: trackedItemComp
        Item {
            id: rootItem
            property alias trackerRef: tracker
            property alias leafRef: leaf

            Item {
                id: mid
                Item {
                    id: leaf
                    property bool payload: false // 仅作场景锚点
                }
            }

            ItemTracker {
                id: tracker
                target: leaf
            }
        }
    }

    Component {
        id: plainObjectComp
        Item {
            property alias trackerRef: tracker
            // 无 item 祖先的普通对象（无 parent，引擎根对象）
            property QtObject plainObj: Qt.createQmlObject(
                "import QtQuick; QtObject {}")

            ItemTracker {
                id: tracker
                target: plainObj
            }
        }
    }

    function test_itemEnabled_defaultsTrue() {
        const scene = createTemporaryObject(trackedItemComp, root)
        tryCompare(scene.trackerRef, "itemEnabled", true, 1000)
        compare(scene.trackerRef.windowActived, true)
        verify(scene.trackerRef.item !== null)
    }

    function test_plainObject_noItemAncestor() {
        const scene = createTemporaryObject(plainObjectComp, root)
        // 无 item 祖先 → item null、enabled true（未追踪 = 正常态）
        tryCompare(scene.trackerRef, "item", null, 1000)
        compare(scene.trackerRef.itemEnabled, true)
        compare(scene.trackerRef.windowActived, true)
    }

    function test_itemEnabled_followsDisable() {
        const scene = createTemporaryObject(trackedItemComp, root)
        tryCompare(scene.trackerRef, "itemEnabled", true, 1000)
        // 禁用 leaf → itemEnabled 跟随（flow-on）
        scene.leafRef.enabled = false
        tryCompare(scene.trackerRef, "itemEnabled", false, 1000)
        // 恢复 → 跟随
        scene.leafRef.enabled = true
        tryCompare(scene.trackerRef, "itemEnabled", true, 1000)
    }

    function test_itemEnabled_ancestorChain() {
        const scene = createTemporaryObject(trackedItemComp, root)
        tryCompare(scene.trackerRef, "itemEnabled", true, 1000)
        // 禁用祖先 mid → isEnabled 链合取为 false
        const mid = scene.leafRef.parent
        mid.enabled = false
        tryCompare(scene.trackerRef, "itemEnabled", false, 1000)
        // 恢复祖先 → 链恢复
        mid.enabled = true
        tryCompare(scene.trackerRef, "itemEnabled", true, 1000)
    }

    function test_window_existsInQmlTest() {
        const scene = createTemporaryObject(trackedItemComp, root)
        // QML TestCase 运行在 QQuickView 内：window 非空
        tryCompare(scene.trackerRef, "windowActived", true, 1000)
        verify(scene.trackerRef.window !== null)
    }
}
