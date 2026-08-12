import QtQuick
import QtTest
import Qool

// Crystal 组件测试（Qool/Crystal.qml）
//
// 被测契约：
// - 默认状态自洽（implicit 20×20、color 默认 Style.accent、strokeColor 自动对比）
// - cutSize 派生跟随尺寸（= shortEdge/2）
// - containmentMask 接入（CrystalGadget，非 null）
// - 掩码契约（直接调用掩码 contains——与 C++ 测试同契约，组件级验证）：
//   中心命中、四角切角域不命中、斜边/顶点开集命中、矩形外不命中（三形态）
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例；绑定传播异步，
// 尺寸变化后 tryCompare 轮询 cutSize 再断言掩码。

TestCase {
    id: root

    name: "Crystal"
    width: 300
    height: 300

    function makeCrystal(size) {
        const c = createTemporaryObject(crystalComp, root, {})
        c.width = size.w
        c.height = size.h
        return c
    }

    Component {
        id: crystalComp
        Crystal {}
    }

    // 掩码契约辅助：等待几何绑定传播后断言掩码判定
    function expectContains(crystal, px, py, expected, tag) {
        tryCompare(crystal, "cutSize", Math.min(crystal.width, crystal.height) / 2, 1000)
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
        compare(c.color, c.Style.accent)
        verify(c.strokeColor !== undefined)
        verify(c.containmentMask !== null)
    }

    function test_cutSizeFollowsSize() {
        const c = makeCrystal({ w: 100, h: 80 })
        tryCompare(c, "cutSize", 40, 1000)
        c.width = 60
        c.height = 60
        tryCompare(c, "cutSize", 30, 1000)
    }

    function test_maskWideHexagon() {
        const c = makeCrystal({ w: 100, h: 80 }) // cut=40 六边形
        expectContains(c, 50, 40, true, "中心")
        expectContains(c, 40, 40, true, "内部")
        expectContains(c, 20, 20, true, "斜边")
        expectContains(c, 100, 40, true, "RT 顶点")
        expectContains(c, 0, 40, true, "LT 顶点")
        expectContains(c, 10, 10, false, "左上角域")
        expectContains(c, 90, 10, false, "右上角域")
        expectContains(c, 90, 70, false, "右下角域")
        expectContains(c, 10, 70, false, "左下角域")
        expectContains(c, 150, 40, false, "矩形外")
    }

    function test_maskDiamond() {
        const c = makeCrystal({ w: 80, h: 80 }) // cut=40 菱形
        expectContains(c, 40, 40, true, "中心")
        expectContains(c, 40, 0, true, "上尖")
        expectContains(c, 80, 40, true, "右尖")
        expectContains(c, 20, 20, true, "斜边")
        expectContains(c, 10, 10, false, "左上角域")
        expectContains(c, 70, 70, false, "右下角域")
    }

    function test_maskTallHexagon() {
        const c = makeCrystal({ w: 80, h: 100 }) // cut=40 瘦六边形
        expectContains(c, 40, 50, true, "中心")
        expectContains(c, 40, 0, true, "上尖")
        expectContains(c, 80, 50, true, "右直边")
        expectContains(c, 10, 10, false, "左上角域")
        expectContains(c, 70, 10, false, "右上角域")
    }

    function test_maskFollowsSizeChange() {
        const c = makeCrystal({ w: 100, h: 80 })
        expectContains(c, 10, 10, false, "大尺寸角域")
        c.width = 40
        c.height = 40 // cut=20：(10,10) 变为斜边命中
        expectContains(c, 10, 10, true, "小尺寸斜边")
        expectContains(c, 5, 5, false, "小尺寸角域")
    }
}
