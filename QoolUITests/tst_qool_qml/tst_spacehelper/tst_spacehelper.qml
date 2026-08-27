import QtQuick
import QtTest
import Qool

// SpaceHelper 行为契约测试（QML 面）
//
// 被测契约（docs/reference/Qool/SpaceHelper.md）：
// - 默认值（width/height=100，偏移=0）
// - 派生区域公式：content/background/margin 三区域宽高与 rect
// - 聚合镜像语义：padding/inset/margin 是最近一次批量写入的镜像，
//   单独改边不更新聚合（读取可能失真）
// - 原子批量写 setPaddings/setInsets/setMargins（top,right,bottom,left；
//   不改聚合镜像）
// - 偏移不做校验（负值进入算术）
// - bindable 属性：QML 绑定（width: parent.width）正常工作
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（状态隔离规范）。

TestCase {
    id: root

    name: "SpaceHelper"
    width: 300
    height: 200

    Component {
        id: plainComp
        SpaceHelper {}
    }

    Component {
        id: paddedComp
        SpaceHelper {
            width: 200
            height: 120
            topPadding: 5
            bottomPadding: 7
            leftPadding: 3
            rightPadding: 11
        }
    }

    function test_defaults() {
        const s = createTemporaryObject(plainComp, root)
        compare(s.width, 100)
        compare(s.height, 100)
        compare(s.topPadding, 0)
        compare(s.bottomPadding, 0)
        compare(s.leftPadding, 0)
        compare(s.rightPadding, 0)
        compare(s.padding, 0)
        compare(s.topInset, 0)
        compare(s.bottomInset, 0)
        compare(s.leftInset, 0)
        compare(s.rightInset, 0)
        compare(s.inset, 0)
        compare(s.topMargin, 0)
        compare(s.bottomMargin, 0)
        compare(s.leftMargin, 0)
        compare(s.rightMargin, 0)
        compare(s.margin, 0)
        // 派生区域 = 盒子本身
        compare(s.rect.x, 0); compare(s.rect.y, 0)
        compare(s.rect.width, 100); compare(s.rect.height, 100)
        compare(s.contentRect.x, 0); compare(s.contentRect.y, 0)
        compare(s.contentRect.width, 100); compare(s.contentRect.height, 100)
        compare(s.backgroundRect.x, 0); compare(s.backgroundRect.y, 0)
        compare(s.backgroundRect.width, 100); compare(s.backgroundRect.height, 100)
        compare(s.marginRect.x, 0); compare(s.marginRect.y, 0)
        compare(s.marginRect.width, 100); compare(s.marginRect.height, 100)
    }

    function test_derivedRegion_formulas() {
        const s = createTemporaryObject(paddedComp, root)
        // contentRect：rect 按 paddings 内缩
        tryCompare(s, "contentRect", Qt.rect(3, 5, 186, 108), 1000)
        // backgroundRect：rect 按 insets 内缩（此处 inset 全 0 → = rect）
        tryCompare(s, "backgroundRect", Qt.rect(0, 0, 200, 120), 1000)
        // marginRect：rect 按 margins 外扩（margin 全 0 → = rect）
        tryCompare(s, "marginRect", Qt.rect(0, 0, 200, 120), 1000)
    }

    function test_aggregate_mirror_semantics() {
        const s = createTemporaryObject(plainComp, root)
        // 批量写入 → 聚合 = 该值，四边同时生效
        s.padding = 12
        compare(s.padding, 12)
        compare(s.topPadding, 12)
        compare(s.bottomPadding, 12)
        compare(s.leftPadding, 12)
        compare(s.rightPadding, 12)
        // 单独改一边 → 聚合不跟随（镜像而非派生）
        s.topPadding = 5
        compare(s.topPadding, 5)
        compare(s.padding, 12) // 仍为最近一次批量写入的值
        // 再次批量 → 聚合更新
        s.padding = 3
        compare(s.padding, 3)
        compare(s.bottomPadding, 3)
    }

    function test_atomicBulkSets() {
        const s = createTemporaryObject(plainComp, root)
        // 原子性：通知一次性交付——最终状态一致即可观察
        s.setPaddings(1, 2, 3, 4) // top, right, bottom, left
        compare(s.topPadding, 1)
        compare(s.rightPadding, 2)
        compare(s.bottomPadding, 3)
        compare(s.leftPadding, 4)

        s.setInsets(5, 6, 7, 8)
        compare(s.topInset, 5)
        compare(s.rightInset, 6)
        compare(s.bottomInset, 7)
        compare(s.leftInset, 8)

        s.setMargins(9, 10, 11, 12)
        compare(s.topMargin, 9)
        compare(s.rightMargin, 10)
        compare(s.bottomMargin, 11)
        compare(s.leftMargin, 12)

        // 批量写不改聚合镜像（仍为默认 0）
        compare(s.padding, 0)
        compare(s.inset, 0)
        compare(s.margin, 0)
    }

    function test_negativeOffsets_notValidated() {
        const s = createTemporaryObject(plainComp, root)
        // 负 padding → 内容区大于盒子
        s.leftPadding = -10
        s.rightPadding = -10
        compare(s.contentRect.x, -10)
        compare(s.contentRect.width, 120)
        // 超盒偏移 → 区域反转（无钳制无报错）
        s.topPadding = 150
        compare(s.contentRect.height, -50)
    }

    function test_bindable_qmlBinding() {
        // bindable 属性：QML 绑定正常——声明式绑定场景
        const s = createTemporaryObject(plainComp, root)
        const host = Qt.createQmlObject(
            "import QtQuick; Item { property real w: 300 }", root)
        // 绑定（非赋值）：width 跟随 host.w
        s.width = Qt.binding(function() { return host.w })
        tryCompare(s, "width", 300, 1000)
        host.w = 400
        tryCompare(s, "width", 400, 1000)
    }

    function test_derivedReadonly_notAssignable() {
        const s = createTemporaryObject(plainComp, root)
        // 派生属性只读：QML 赋值抛异常（无 setter）——捕获并断言
        let threw = false
        try {
            s.contentRect = Qt.rect(1, 2, 3, 4)
        } catch (e) {
            threw = true
        }
        verify(threw, "只读属性赋值应抛异常")
        compare(s.contentRect.x, 0)
        compare(s.contentRect.width, 100)
    }
}
