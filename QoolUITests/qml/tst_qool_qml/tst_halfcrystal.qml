import QtQuick
import QtTest
import Qool

// HalfCrystal 组件测试（Qool/HalfCrystal.qml）
//
// 被测契约：
// - 默认状态自洽（显式 20×20、direction = Qore.N 三角形形态、
//   color/borderColor/borderWidth 默认值）
// - 显式尺寸契约：width/height 不被 Shape 引擎触碰（引擎只覆盖
//   implicit——implicit 不承诺，随路径边界）
// - 命中掩码 = gB（内接画布矩形——RectGadget 数值 contains，非
//   FillContains 判定）：containmentMask 非空、命中 = 画布矩形
// - direction 写读与五种形态几何（渲染路径点——公开视觉契约）：
//   N/S/W/E 直角等腰三角形（对侧点落中心）+ 其余值菱形（四边中点）
// - 内描边（双层模型）：内路径 = 外路径内缩（直角内缩 √2·b、尖角内缩
//   (1+√2)·b 水平 / b 垂直），borderWidth 跟随；borderWidth < 1 不描边
// - 非正方形尺寸下内接画布语义（基于内部最大正方形）
//
// 渲染路径经 objectName（borderPath/fillPath）读取（组件内部对象零暴露
// 原则的测试例外——几何契约是公开视觉行为，路径点即渲染配置的直接输出）。
//
// 异步断言：方向切换经 states 应用形态（不提供动画——直接切换）；
// 断言前轮询路径点最终值（tryVerify——state 绑定值稳定）。
//
// 注：本文件不再触发 "No ThemeLoader installed" WARN（ThemeDB 进程级单例，
// 已在 tst_crystal.qml::test_cutSizeFollowsSize 首次初始化时经 ignoreWarning
// 处理；若未来批次顺序变化导致先触发，需把注册移到新的首个触发点）。
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例。

TestCase {
    id: root

    name: "HalfCrystal"
    width: 300
    height: 300

    Component {
        id: crystalComp
        HalfCrystal {}
    }

    // 20×20 组件：内接画布 = 整组件（cx=10, cy=10, halfS=10）。
    // 路径 = start + 4 PathLine（末段 = 闭合回起点）——expected 含闭合点。
    readonly property var shapeN: [Qt.point(10, 0), Qt.point(20, 10), Qt.point(10, 10), Qt.point(0, 10), Qt.point(10, 0)]
    readonly property var shapeS: [Qt.point(10, 10), Qt.point(20, 10), Qt.point(10, 20), Qt.point(0, 10), Qt.point(10, 10)]
    readonly property var shapeW: [Qt.point(10, 0), Qt.point(10, 10), Qt.point(10, 20), Qt.point(0, 10), Qt.point(10, 0)]
    readonly property var shapeE: [Qt.point(10, 0), Qt.point(20, 10), Qt.point(10, 20), Qt.point(10, 10), Qt.point(10, 0)]
    readonly property var shapeDiamond: [Qt.point(10, 0), Qt.point(20, 10), Qt.point(10, 20), Qt.point(0, 10), Qt.point(10, 0)]

    // 内描边（borderWidth=1）：直角内缩 = √2、尖角内缩x = 1+√2、尖角内缩y = 1
    readonly property var insetN: [Qt.point(10, Math.SQRT2), Qt.point(20 - (1 + Math.SQRT2), 9),
                                Qt.point(10, 9), Qt.point(1 + Math.SQRT2, 9), Qt.point(10, Math.SQRT2)]
    readonly property var insetDiamond: [Qt.point(10, Math.SQRT2), Qt.point(20 - Math.SQRT2, 10),
                                      Qt.point(10, 20 - Math.SQRT2), Qt.point(Math.SQRT2, 10),
                                      Qt.point(10, Math.SQRT2)]

    function makeCrystal(size, direction) {
        const c = createTemporaryObject(crystalComp, root, {})
        c.width = size.w
        c.height = size.h
        if (direction !== undefined)
            c.direction = direction
        return c
    }

    // —— 渲染路径读取辅助（objectName 定位 + PathLine 子对象）——
    function findPath(c, name) {
        for (let i = 0; i < c.data.length; ++i) {
            if (c.data[i].objectName === name)
                return c.data[i]
        }
        return null
    }

    function pathPoints(path) {
        // ShapePath 非 QQuickItem——children 属性在 QML 不可见（undefined）；
        // 子路径元素（PathLine）经 Path 的 pathElements 列表遍历
        const pts = [Qt.point(path.startX, path.startY)]
        const els = path.pathElements
        for (let i = 0; i < els.length; ++i) {
            const child = els[i]
            if (child !== null && child !== undefined && "x" in child && "y" in child)
                pts.push(Qt.point(child.x, child.y))
        }
        return pts
    }

    function pointsMatch(pts, expected) {
        if (pts.length !== expected.length)
            return false
        for (let i = 0; i < pts.length; ++i) {
            if (Math.abs(pts[i].x - expected[i].x) > 0.01
                    || Math.abs(pts[i].y - expected[i].y) > 0.01)
                return false
        }
        return true
    }

    function expectShape(c, pathName, expected, tag) {
        const path = findPath(c, pathName)
        verify(path !== null, tag + "：未找到路径 " + pathName)
        tryVerify(function() { return pointsMatch(pathPoints(path), expected) },
            1000, tag)
    }

    function test_defaults() {
        const c = makeCrystal({ w: 20, h: 20 })
        compare(c.direction, Qore.N)
        compare(c.color, c.Style.accent)
        verify(c.borderColor !== undefined)
        compare(c.borderWidth, 1)
        // 命中掩码 = gB（内接画布矩形——RectGadget 数值 contains，
        // 非 FillContains 判定；掩码对象非 Item 可被多 Item 引用）
        verify(c.containmentMask !== null, "命中掩码 = gB（内接画布矩形）")
    }

    // —— 渲染路径读取辅助（objectName 定位 + PathLine 子对象）——

    function test_explicitSizeStable() {
        // 显式 width/height 不被 Shape 引擎触碰（引擎只覆盖 implicit——
        // implicit 不承诺，随路径边界）；渲染基于显式尺寸的内接画布
        const c = makeCrystal({ w: 40, h: 30 })
        compare(c.width, 40)
        compare(c.height, 30)
        c.width = 60
        c.height = 60
        compare(c.width, 60)
        compare(c.height, 60)
        // 60×60 N 态：内接画布 = 整组件——外轮廓基于新尺寸
        const expected = [Qt.point(30, 0), Qt.point(60, 30),
                          Qt.point(30, 30), Qt.point(0, 30), Qt.point(30, 0)]
        expectShape(c, "borderPath", expected, "60×60 外轮廓")
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

    function test_shapeDirectionN() {
        const c = makeCrystal({ w: 20, h: 20 }, Qore.N)
        expectShape(c, "borderPath", shapeN, "N 三角外轮廓")
        expectShape(c, "fillPath", insetN, "N 三角内描边")
    }

    function test_shapeDirectionS() {
        const c = makeCrystal({ w: 20, h: 20 }, Qore.S)
        expectShape(c, "borderPath", shapeS, "S 三角外轮廓")
    }

    function test_shapeDirectionW() {
        const c = makeCrystal({ w: 20, h: 20 }, Qore.W)
        expectShape(c, "borderPath", shapeW, "W 三角外轮廓")
    }

    function test_shapeDirectionE() {
        const c = makeCrystal({ w: 20, h: 20 }, Qore.E)
        expectShape(c, "borderPath", shapeE, "E 三角外轮廓")
    }

    function test_shapeDiamondDefault() {
        // Unknown 与对角方向 → 菱形（四边中点——默认状态，无 State）
        const c = makeCrystal({ w: 20, h: 20 }, Qore.Unknown)
        expectShape(c, "borderPath", shapeDiamond, "菱形外轮廓")
        expectShape(c, "fillPath", insetDiamond, "菱形内描边")

        const c2 = makeCrystal({ w: 20, h: 20 }, Qore.SE)
        expectShape(c2, "borderPath", shapeDiamond, "SE 菱形外轮廓")
    }

    function test_shapeSwitchAnimationSettles() {
        // 方向切换（states/Transition 动画）后稳定到目标形态
        const c = makeCrystal({ w: 20, h: 20 }, Qore.N)
        c.direction = Qore.W
        expectShape(c, "borderPath", shapeW, "N→W 切换稳定")
        c.direction = Qore.Unknown
        expectShape(c, "borderPath", shapeDiamond, "W→菱形 切换稳定")
    }

    function test_borderWidthFollows() {
        // borderWidth 扩大 → 内描边按中间量放大（直角内缩 √2·b 等）
        const c = makeCrystal({ w: 20, h: 20 }, Qore.N)
        c.borderWidth = 2
        const expected = [Qt.point(10, 2 * Math.SQRT2),
                          Qt.point(20 - 2 * (1 + Math.SQRT2), 8),
                          Qt.point(10, 8),
                          Qt.point(2 * (1 + Math.SQRT2), 8),
                          Qt.point(10, 2 * Math.SQRT2)]
        expectShape(c, "fillPath", expected, "borderWidth=2 内描边")
        // 外轮廓不受 borderWidth 影响
        expectShape(c, "borderPath", shapeN, "borderWidth=2 外轮廓不变")
    }

    function test_borderWidthBelowOne() {
        // borderWidth < 1 不描边（阈值语义）：内四点 = 外四点（fillPath
        // 覆盖 borderPath——纯色填充）
        const c = makeCrystal({ w: 20, h: 20 }, Qore.N)
        c.borderWidth = 0.5
        expectShape(c, "fillPath", shapeN, "borderWidth=0.5 不描边（内=外）")
        c.borderWidth = 0
        expectShape(c, "fillPath", shapeN, "borderWidth=0 不描边（内=外）")
        c.borderWidth = -1
        expectShape(c, "fillPath", shapeN, "borderWidth=-1 不描边（内=外）")
    }

    function test_nonSquareCanvasSemantics() {
        // 40×30：内接画布 = 30×30（shortEdge），居中 (5,0) 起——顶点基于
        // 画布四边中点（不随外框拉伸）
        const c = makeCrystal({ w: 40, h: 30 }, Qore.N)
        // 画布本地：x∈[5,35]、y∈[0,30]——topCenter(20,0) bottomCenter(20,30)
        // leftCenter(5,15) rightCenter(35,15) center(20,15)
        const expected = [Qt.point(20, 0), Qt.point(35, 15),
                          Qt.point(20, 15), Qt.point(5, 15), Qt.point(20, 0)]
        expectShape(c, "borderPath", expected, "非方形内接画布语义")
    }
}
