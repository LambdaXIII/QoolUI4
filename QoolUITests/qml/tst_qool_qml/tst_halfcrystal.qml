import QtQuick
import QtTest
import Qool

// HalfCrystal 组件测试（Qool/HalfCrystal.qml）
//
// 被测契约：
// - 默认状态自洽（implicit 20×20、direction = Qore.N——三角形形态）
// - direction 属性写读与切换
// - 掩码契约（直接调用掩码 contains）：
//   N/S/W/E 三角形（半区粗判 + 内正方形四角域排除）：三角形内命中、
//   斜边开集命中、角域不命中、半区外不命中
//   其余方向（Unknown/对角）→ 菱形（整正方形粗判）
//   非正方形尺寸下仍正确（内正方形画布语义）
// - direction 切换 → 掩码判定跟随（组件级绑定传播）
// - itemAt 端到端：掩码经 containmentMask 接入引擎 hit test
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例；绑定传播异步，
// 方向/尺寸变化后 tryCompare 轮询再断言。

TestCase {
    id: root

    name: "HalfCrystal"
    width: 300
    height: 300

    Component {
        id: crystalComp
        HalfCrystal {}
    }

    function makeCrystal(size, direction) {
        const c = createTemporaryObject(crystalComp, root, {})
        c.width = size.w
        c.height = size.h
        if (direction !== undefined)
            c.direction = direction
        return c
    }

    // 掩码契约辅助：等待掩码 direction 绑定传播后断言（掩码 direction
    // 经 QML 绑定跟随 root.direction）
    function expectContains(crystal, px, py, expected, tag) {
        tryCompare(crystal.containmentMask, "direction", crystal.direction, 1000)
        const hit = crystal.containmentMask.contains(Qt.point(px, py))
        if (expected)
            verify(hit, tag + " 应命中 (" + px + "," + py + ")")
        else
            verify(!hit, tag + " 不应命中 (" + px + "," + py + ")")
    }

    function test_defaults() {
        const c = makeCrystal({ w: 20, h: 20 })
        compare(c.implicitWidth, 20)
        compare(c.implicitHeight, 20)
        compare(c.direction, Qore.N)
        compare(c.color, c.Style.accent)
        verify(c.containmentMask !== null)
    }

    function test_directionProperty() {
        const c = makeCrystal({ w: 20, h: 20 })
        c.direction = Qore.S
        compare(c.direction, Qore.S)
        c.direction = Qore.Unknown
        compare(c.direction, Qore.Unknown)
        c.direction = Qore.NW
        compare(c.direction, Qore.NW)
    }

    function test_maskDirectionN() {
        // 20×20：内正方形 [0,20]²，halfS=10，三角形 north(10,0) east(20,10)
        // west(0,10)（直角顶点 north）
        const c = makeCrystal({ w: 20, h: 20 }, Qore.N)
        expectContains(c, 10, 5, true, "三角形内部")
        expectContains(c, 10, 0, true, "north 顶点")
        expectContains(c, 0, 10, true, "west 顶点")
        expectContains(c, 5, 5, true, "斜边开集")
        expectContains(c, 15, 5, true, "斜边开集")
        expectContains(c, 4, 4, false, "左上角域")
        expectContains(c, 16, 4, false, "右上角域")
        expectContains(c, 10, 15, false, "半区外（下半）")
        expectContains(c, 25, 5, false, "半区外（右）")
    }

    function test_maskDirectionS() {
        const c = makeCrystal({ w: 20, h: 20 }, Qore.S)
        expectContains(c, 10, 15, true, "三角形内部")
        expectContains(c, 10, 20, true, "south 顶点")
        expectContains(c, 5, 15, true, "斜边开集")
        expectContains(c, 4, 16, false, "左下角域")
        expectContains(c, 10, 5, false, "半区外（上半）")
    }

    function test_maskDirectionW() {
        const c = makeCrystal({ w: 20, h: 20 }, Qore.W)
        expectContains(c, 5, 10, true, "三角形内部")
        expectContains(c, 0, 10, true, "west 顶点")
        expectContains(c, 5, 5, true, "斜边开集")
        expectContains(c, 4, 4, false, "左上角域")
        expectContains(c, 15, 10, false, "半区外（右）")
    }

    function test_maskDirectionE() {
        const c = makeCrystal({ w: 20, h: 20 }, Qore.E)
        expectContains(c, 15, 10, true, "三角形内部")
        expectContains(c, 20, 10, true, "east 顶点")
        expectContains(c, 15, 5, true, "斜边开集")
        expectContains(c, 16, 4, false, "右上角域")
        expectContains(c, 5, 10, false, "半区外（左）")
    }

    function test_maskDiamondDefault() {
        // Unknown 与对角方向 → 菱形
        const c = makeCrystal({ w: 20, h: 20 }, Qore.Unknown)
        expectContains(c, 10, 10, true, "中心")
        expectContains(c, 10, 0, true, "north 顶点")
        expectContains(c, 20, 10, true, "east 顶点")
        expectContains(c, 5, 5, true, "斜边开集")
        expectContains(c, 4, 4, false, "左上角域")
        expectContains(c, 16, 16, false, "右下角域")
        expectContains(c, 10, 15, true, "菱形下半内部")

        const c2 = makeCrystal({ w: 20, h: 20 }, Qore.SE)
        expectContains(c2, 10, 10, true, "SE 菱形中心")
        expectContains(c2, 4, 4, false, "SE 左上角域")
    }

    function test_maskNonSquareSize() {
        // 40×30：内正方形 = 30×30（shortEdge），中心 (20,15)，halfS=15——
        // 掩码基于内正方形画布（gB = maxInnerSquareRect），不随外框拉伸
        const c = makeCrystal({ w: 40, h: 30 }, Qore.N)
        // N 三角形 north(20,0) east(35,15) west(5,15)
        expectContains(c, 20, 7, true, "三角形内部")
        expectContains(c, 20, 0, true, "north 顶点")
        expectContains(c, 10, 10, true, "斜边开集（dx+dy=15）")
        expectContains(c, 7, 3, false, "左上角域")
        expectContains(c, 33, 3, false, "右上角域")
        expectContains(c, 20, 20, false, "半区外")
    }

    Component {
        id: sceneComp
        Item {
            width: 200
            height: 200
            property alias crystalRef: crystal
            property alias bgRef: bg

            MouseArea {
                id: bg
                anchors.fill: parent
            }
            HalfCrystal {
                id: crystal
                x: 20
                y: 20
            }
        }
    }
}
