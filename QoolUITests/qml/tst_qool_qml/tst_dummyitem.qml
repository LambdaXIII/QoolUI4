import QtQuick
import QtTest
import Qool

// DummyItem 行为测试（Qool/DummyItem.qml）
//
// 被测契约：
// - 默认值：x/y/z/width/height 均为 0，visible 为 false（属性未显式初始化）
// - boundingRect = Qt.rect(x, y, width, height)，属性变化即时反映
// - contains(p)：p 落在 [0, width] × [0, height] 闭区间内返回 true（边界包含），
//   否则 false；width/height 为 0 时仅 (0,0) 点在内
// - contains 的判定基准是 0 而非自身 x/y —— 组件位置不影响包含判定
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例（状态隔离规范）；
// 本组件无动画/时序依赖，属性断言均为同步绑定求值，直接 compare/verify。

TestCase {
    id: root

    name: "DummyItem"

    Component {
        id: itemComp
        DummyItem {}
    }

    function makeItem() {
        return createTemporaryObject(itemComp, root)
    }

    function test_defaultValues() {
        const item = makeItem()
        compare(item.x, 0)
        compare(item.y, 0)
        compare(item.z, 0)
        compare(item.width, 0)
        compare(item.height, 0)
        compare(item.visible, false)
    }

    function test_boundingRectTracksProperties() {
        const item = makeItem()
        item.x = 10
        item.y = 20
        item.width = 100
        item.height = 50
        compare(item.boundingRect.x, 10)
        compare(item.boundingRect.y, 20)
        compare(item.boundingRect.width, 100)
        compare(item.boundingRect.height, 50)
        // z 不参与 boundingRect（源码 rect 仅含 x/y/width/height）
        item.z = 5
        compare(item.boundingRect.x, 10)
        compare(item.boundingRect.height, 50)
    }

    function test_containsInsideIncludingBoundary() {
        const item = makeItem()
        item.width = 100
        item.height = 50
        // 闭区间：左/上边界 (0,0) 与右/下边界 (100,50) 均包含
        verify(item.contains(Qt.point(0, 0)))
        verify(item.contains(Qt.point(100, 50)))
        verify(item.contains(Qt.point(100, 0)))
        verify(item.contains(Qt.point(0, 50)))
        verify(item.contains(Qt.point(50, 25)))
    }

    function test_containsOutside() {
        const item = makeItem()
        item.width = 100
        item.height = 50
        verify(!item.contains(Qt.point(-1, 0)))    // 左越界
        verify(!item.contains(Qt.point(101, 25)))  // 右越界
        verify(!item.contains(Qt.point(50, -1)))   // 上越界
        verify(!item.contains(Qt.point(50, 51)))   // 下越界
        verify(!item.contains(Qt.point(-1, -1)))   // 角越界
    }

    function test_containsIgnoresOwnPosition() {
        const item = makeItem()
        item.width = 100
        item.height = 50
        item.x = 1000
        item.y = 2000
        // 判定基准是 0 而非 x/y：平移自身位置不影响包含判定
        verify(item.contains(Qt.point(0, 0)))
        verify(item.contains(Qt.point(50, 25)))
        verify(!item.contains(Qt.point(-1, 25)))
    }

    function test_zeroSizedItem() {
        const item = makeItem()
        // width/height = 0：闭区间 [0,0] 仅容纳 (0,0)
        verify(item.contains(Qt.point(0, 0)))
        verify(!item.contains(Qt.point(0, 1)))
        verify(!item.contains(Qt.point(1, 0)))
    }
}
