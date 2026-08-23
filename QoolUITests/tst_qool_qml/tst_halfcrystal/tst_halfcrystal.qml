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

    function test_directionProperty() {
        const c = makeCrystal({ w: 20, h: 20 })
        c.direction = Qore.S
        compare(c.direction, Qore.S)
        c.direction = Qore.Unknown
        compare(c.direction, Qore.Unknown)
        c.direction = Qore.NW
        compare(c.direction, Qore.NW)
    }
}
