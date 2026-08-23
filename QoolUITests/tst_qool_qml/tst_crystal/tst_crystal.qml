import QtQuick
import QtTest
import Qool

// Crystal 组件测试（Qool/Crystal.qml——OctagonShape 特化底座）
//
// 被测契约：
// - 默认状态自洽（默认逻辑尺寸 20×20——width/height 显式默认，implicit
//   由引擎驱动 = 路径边界；color 默认 Style.accent、borderColor 自动对比、borderWidth 默认 1）
// - 四角 cut 恒等契约（settings.cutSizeTL/TR/BL/BR 相等且 = shortEdge/2，
//   随尺寸变化）——切角是几何契约（内部中间量实现），非公开接口
// - containmentMask 接入（QoolBoxShapeControl，非 null）
// - 掩码契约（直接调用掩码 contains——与 C++ 测试同契约，组件级验证）：
//   中心命中、四角切角域不命中、斜边/顶点开集命中、矩形外不命中（三形态）
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例；绑定传播异步，
// 尺寸变化后 tryCompare 轮询 settings 四角再断言掩码。

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

    // 掩码契约辅助：等待几何绑定传播后断言掩码判定。target 尺寸经
    // ShapeControl 信号延迟同步（queued——避免隐式尺寸绑定环），掩码
    // 判定用 control 尺寸缓存——必须先轮询到同步完成，否则 origin/used
    // 停留在旧尺寸（中心点会被错误的角域排除）。
    function expectContains(crystal, px, py, expected, tag) {
        tryCompare(crystal.control, "width", crystal.width, 1000)
        tryCompare(crystal.control, "height", crystal.height, 1000)
        tryCompare(crystal.control.settings, "cutSizeTL",
            Math.min(crystal.width, crystal.height) / 2, 1000)
        const hit = crystal.containmentMask.contains(Qt.point(px, py))
        if (expected)
            verify(hit, tag + " 应命中 (" + px + "," + py + ")")
        else
            verify(!hit, tag + " 不应命中 (" + px + "," + py + ")")
    }

    function test_defaults() {
        const c = makeCrystal({ w: 20, h: 20 })
        compare(c.width, 20)
        compare(c.height, 20)
        tryCompare(c, "implicitWidth", 20, 1000) // 引擎 implicit = 路径边界 = 几何
        compare(c.color, c.Style.accent)
        verify(c.borderColor !== undefined)
        compare(c.borderWidth, 1)
        verify(c.containmentMask !== null)
        verify(c.containmentMask instanceof QoolBoxShapeControl,
            "掩码应委托 QoolBoxShapeControl")
        verify(c.fillGradient === null, "fillGradient 默认 null")
        verify(c.fillItem === null, "fillItem 默认 null")
    }

    function test_fillGradientChannel() {
        // 渐变通道类型链路：ShapePath.fillGradient 官方要求 ShapeGradient
        // 新 API（LinearGradient 等，旧 Gradient 不可用）——Crystal 根 =
        // OctagonShape，fillGradient 即 fillShape 的 alias（ShapeGradient
        // 类型），LinearGradient 赋值必须成功（Slider 轨道渐变同链路）。
        const c = makeCrystal({ w: 60, h: 40 })
        const grad = createTemporaryQmlObject(
            "import QtQuick; import QtQuick.Shapes; LinearGradient { GradientStop { position: 0; color: 'red' } GradientStop { position: 1; color: 'blue' } }", root)
        c.fillGradient = grad
        tryVerify(function() { return c.fillGradient === grad }, 1000,
            "LinearGradient 应成功赋给 fillGradient（ShapeGradient 类型）")
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
