import QtQuick
import QtTest
import Qool

// BasicLabel 背景几何测试（Qool/BasicLabel.qml）
//
// 被测契约：
// - bgBox.control.leftSpace 读法保留：leftPadding/rightPadding 绑定背景
//   QoolBox 的 control 空间量（几何内缩），contentItem 位于 padding 盒内
// - 排版语义：implicitWidth = leftPadding + implicitContentWidth + rightPadding、
//   implicitHeight = topPadding + implicitContentHeight + bottomPadding；
//   背景填满控件几何
// - cutSizeTL/TR/BL/BR 四角生效（背景切角）：settings 四角显式 4，
//   control.ext* 外轮廓点几何可验证——(4,0)/(w-4,0)/(4,h)/(w-4,h)
// - 四角 cut 动态变化 → control.leftSpace 变化 → padding 实时跟随（读法活链）
// - 未显式覆盖的 settings 字段保留 QoolBox 默认：borderWidth 来自
//   Style.controlBorderWidth、fillColor = 标签 color
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例（状态隔离规范）；
// 异步/时序断言一律 tryCompare/tryVerify 轮询（不写固定 sleep）；浮点 fuzzyEq。

TestCase {
    id: root

    name: "BasicLabel"
    width: 400
    height: 300

    Component {
        id: labelComp
        BasicLabel {
            width: 200
            height: 60
            text: "Hello"
        }
    }

    function fuzzyEq(a, b, eps) {
        return Math.abs(a - b) <= (eps === undefined ? 1e-6 : eps)
    }

    // 四角切角生效：settings 四角显式 4；外轮廓点在
    // (4,0)/(w-4,0)/(4,h)/(w-4,h)（八边形背景，四角各切 4）
    function test_backgroundCutCorners() {
        // 期望 WARN（测试环境无主题插件）：本批次第一个实例化 Style 消费
        // 组件的测试——ThemeDB 首次初始化 → PluginLoader 扫描不到
        // qoolplugins/（插件随 example 部署，测试 exe 目录无）→
        // "No ThemeLoader installed" WARN，ThemeDB 回退 system 主题。
        // 对断言无影响（相对值断言）；ignoreWarning 吞掉并验证其出现
        // （未出现会提示——届时说明 ThemeDB 初始化位置变化，需移动本注册
        // 到新的首个触发点）。
        ignoreWarning(new RegExp("No ThemeLoader installed.*"))
        const label = createTemporaryObject(labelComp, root, {})
        const bg = label.background
        tryCompare(bg, "width", 200, 1000) // 背景随控件布局（异步 polish）
        tryCompare(bg, "height", 60, 1000)
        // settings 四角显式特化（cutSizes: 4 → 四角独立）
        compare(bg.settings.cutSizeTL, 4)
        compare(bg.settings.cutSizeTR, 4)
        compare(bg.settings.cutSizeBL, 4)
        compare(bg.settings.cutSizeBR, 4)
        // 未覆盖字段保留 QoolBox 默认：边框宽来自 Style、填充 = 标签 color
        compare(bg.settings.borderWidth, Style.controlBorderWidth)
        compare(bg.settings.fillColor, label.color)
        // 切角几何（target 本地系外轮廓点；borderWidth 0 的 outer 环）
        tryVerify(function () {
            return fuzzyEq(bg.control.extTLx, 4) && fuzzyEq(bg.control.extTLy, 0)
        }, 1000)
        tryVerify(function () {
            return fuzzyEq(bg.control.extTRx, 200 - 4) && fuzzyEq(bg.control.extTRy, 0)
        }, 1000)
        tryVerify(function () {
            return fuzzyEq(bg.control.extBLx, 4) && fuzzyEq(bg.control.extBLy, 60)
        }, 1000)
        tryVerify(function () {
            return fuzzyEq(bg.control.extBRx, 200 - 4) && fuzzyEq(bg.control.extBRy, 60)
        }, 1000)
    }

    // bgBox.control.leftSpace 读法：padding 绑定 control 空间量（几何内缩）
    function test_leftSpaceReadThrough() {
        const label = createTemporaryObject(labelComp, root, {})
        const bg = label.background
        tryCompare(bg, "width", 200, 1000)
        // 背景布局（0 → 200）后 control 空间量才稳定：轮询两侧再核对同一性
        tryCompare(bg.control, "leftSpace", 4, 1000)
        tryCompare(label, "leftPadding", 4, 1000)
        tryCompare(bg.control, "rightSpace", 4, 1000)
        tryCompare(label, "rightPadding", 4, 1000)
        compare(label.leftPadding, bg.control.leftSpace)
        compare(label.rightPadding, bg.control.rightSpace)
        // 内容内缩：contentItem 起点 = leftPadding
        tryVerify(function () {
            return fuzzyEq(label.contentItem.x, label.leftPadding)
        }, 1000)
    }

    // 排版语义：implicitWidth/Height 含双侧 padding；背景填满控件；
    // 内容盒宽 = 剩余区
    function test_layoutSemantics() {
        const label = createTemporaryObject(labelComp, root, {})
        const bg = label.background
        tryCompare(bg, "width", 200, 1000)
        tryVerify(function () {
            return fuzzyEq(label.implicitWidth,
                label.leftPadding + label.implicitContentWidth + label.rightPadding)
        }, 1000)
        tryVerify(function () {
            return fuzzyEq(label.implicitHeight,
                label.topPadding + label.implicitContentHeight + label.bottomPadding)
        }, 1000)
        // 背景几何 = 控件几何（background 填满）
        tryVerify(function () {
            return fuzzyEq(bg.width, label.width) && fuzzyEq(bg.height, label.height)
        }, 1000)
        // 内容盒 = padding 内缩后的剩余区
        tryVerify(function () {
            return fuzzyEq(label.contentItem.width,
                label.width - label.leftPadding - label.rightPadding)
        }, 1000)
    }

    // 四角 cut 动态变化 → control.leftSpace 变化 → padding 实时跟随（读法活链）
    function test_paddingFollowsCutChange() {
        const label = createTemporaryObject(labelComp, root, {})
        const bg = label.background
        tryCompare(bg.control, "leftSpace", 4, 1000)
        // 只改左上切角：leftSpace = max(cutTL, cutBL) = 20；right 侧不变
        bg.settings.cutSizeTL = 20
        tryCompare(bg.control, "leftSpace", 20, 1000)
        tryCompare(label, "leftPadding", 20, 1000)
        tryCompare(label, "rightPadding", 4, 1000)
        tryVerify(function () {
            return fuzzyEq(label.contentItem.x, 20)
        }, 1000)
    }
}
