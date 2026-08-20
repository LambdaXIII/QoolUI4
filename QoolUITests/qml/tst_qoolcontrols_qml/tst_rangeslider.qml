import QtQuick
import QtTest
import Qool
import Qool.Controls

// RangeSlider 测试（Qool.Controls/RangeSlider.qml——T.RangeSlider 模板 +
// 默认窄条 handle 激活模板交互 + Crystal 轨道 + contentItem 内 rangeBox
// 区间盒前景 hover 展开）
//
// 被测契约（外部行为与公开契约——不测内部实现）：
// - 默认状态自洽（color/backgroundColor/borderColor 默认、两手柄值 0/1、
//   first/second handle 存在）
// - handle 几何：窄条（width = availableHeight/2）、不相交公式（行程 =
//   availableWidth − width×2，first 从 0、second 从 width——任意值不相交）
// - 区间盒（值→位置映射）：rangeBox.x = first.visualPosition × (可用宽 − 高)、
//   width = (可用宽 − 高) × (second − first) + 高——左缘 = first handle 左缘、
//   右缘 = second handle 右缘
// - 前景常态尺寸：rangeCrystal = rangeBox 尺寸 − shrinkSize（hover 展开
//   为模板不可达——人工验收）
// - 键盘步进：increase()/decrease() 按 stepSize 步进（模板方法公开可调）
// - 程序化赋值不吸附：snapMode/stepSize 下 setValues 不吸附
// - 端点钳制：程序化写值模板钳制（first ∈ [from, second]、second ∈ [first, to]）
// - 倒置范围（from > to）：位置反向、区间仍正向
// - handle 插拔：替换 first.handle（模板 handle 插拔契约）
//
// 注：真实鼠标交互（模板拖动、snap/live 拖动路径、hover 展开）不在自动化
// 范围——合成鼠标事件对 Quick Controls 模板不可达（探针实测）；交互契约以
// spec/示例页人工验收。
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例；动画关闭。
//
// 测试基准：200×40 → shrinkSize = bound(3, 10, 25) = 10、availableWidth =
// 200、availableHeight = 40、handle w = 20/h = 40、行程 = 200 − 40 = 160；
// rangeBox 高 = 40、x = firstVP × 160、宽 = 160 × (second−first) + 40。
// LTR 水平下 visualPosition = position。

TestCase {
    id: root

    name: "RangeSlider"
    width: 400
    height: 300

    Component {
        id: sliderComp
        RangeSlider {
            width: 200
            height: 40
            animationEnabled: false
        }
    }

    // first.handle 替换组件（行为插拔最低要求——任意 Item 替换）
    Component {
        id: sliderWithCustomHandle
        RangeSlider {
            width: 200
            height: 40
            animationEnabled: false
            first.handle: Rectangle {
                objectName: "customHandle"
                width: 10
                height: 10
                color: "red"
            }
        }
    }

    function makeSlider(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(sliderComp, root, props)
    }

    // —— 内部对象读取辅助（组件内部对象零暴露原则的测试例外——前景/区间
    // 盒是公开视觉契约）：contentItem 首子项 = rangeBox、rangeBox 首子项 =
    // rangeCrystal（HoverHandler/ItemAnimatedResizer 非 Item，不在 children）——
    function rangeBox(s) {
        return s.contentItem.children[0]
    }
    function rangeCrystal(s) {
        return rangeBox(s).children[0]
    }

    function test_defaults() {
        const s = makeSlider({})
        compare(s.color, s.Style.accent)
        compare(s.backgroundColor, s.Style.buttonText)
        compare(s.borderColor, ThemeHQ.recommendForeground(s.backgroundColor))
        compare(s.first.value, 0)
        compare(s.second.value, 1)
        verify(s.first.handle !== null, "first handle 存在")
        verify(s.second.handle !== null, "second handle 存在")
        verify(s.contentItem !== null, "contentItem 存在")
    }

    function test_handleGeometry() {
        // 窄条（w = h/2）+ 不相交公式：行程 = availableWidth − width×2，
        // first 从 0、second 从 width 起——任意值下 first 右缘 <= second 左缘
        const s = makeSlider({})
        const fh = s.first.handle
        const sh = s.second.handle
        compare(fh.width, 20, "w = availableHeight/2")
        compare(fh.height, 40, "h = availableHeight")
        compare(sh.width, 20)
        compare(sh.height, 40)
        // 默认（first=0 second=1）：first 左缘 0、second 右缘 200
        compare(fh.x, 0, "first position 0 → x=0")
        compare(sh.x, 180, "second position 1 → x = width + 160 = 180，左缘 180")
        compare(sh.x + sh.width, 200, "second 右缘贴控件右端")
        // 不相交：first 右缘 <= second 左缘
        verify(fh.x + fh.width <= sh.x, "默认不相交")
        // 写值 → handle 跟随（不相交保持）
        s.setValues(0.25, 0.75)
        compare(fh.x, 0.25 * 160)
        compare(sh.x, 20 + 0.75 * 160)
        verify(fh.x + fh.width <= sh.x, "写值后不相交")
        // 端点重合：first 右缘恰好贴 second 左缘（相邻不重叠）
        s.setValues(0.5, 0.5)
        compare(fh.x + fh.width, sh.x, "重合时相邻不重叠")
    }

    function test_rangeBoxGeometry() {
        // 区间盒：x = firstVP × 160、宽 = 160 × (second−first) + 40；
        // 左缘 = first handle 左缘、右缘 = second handle 右缘
        const s = makeSlider({})
        const rb = rangeBox(s)
        compare(rb.height, 40)
        // 默认（0,1）：x=0、宽 = 160 + 40 = 200
        compare(rb.x, 0)
        compare(rb.width, 200)
        compare(rb.x, s.first.handle.x, "区间盒左缘 = first handle 左缘")
        compare(rb.x + rb.width, s.second.handle.x + s.second.handle.width, "区间盒右缘 = second handle 右缘")
        // 写值 → 区间盒跟随
        s.setValues(0.25, 0.75)
        compare(rb.x, 0.25 * 160)
        compare(rb.width, 160 * 0.5 + 40)
        compare(rb.x, s.first.handle.x)
        compare(rb.x + rb.width, s.second.handle.x + s.second.handle.width)
    }

    function test_foregroundRest() {
        // 前景常态（resized=false，hover 不可达）：rangeCrystal = rangeBox
        // 尺寸 − shrinkSize（收缩量 10）、居中于区间盒
        const s = makeSlider({})
        const rb = rangeBox(s)
        const rc = rangeCrystal(s)
        verify(rc !== undefined, "rangeCrystal 存在")
        compare(rc.width, rb.width - 10, "前景常态宽 = 区间盒宽 − 收缩量")
        compare(rc.height, rb.height - 10, "前景常态高 = 区间盒高 − 收缩量")
        // 值变化 → rangeBox 宽变，前景常态随之
        s.setValues(0.25, 0.75)
        compare(rb.width, 160 * 0.5 + 40)
        compare(rc.width, rb.width - 10, "前景常态跟随区间盒")
    }

    function test_keyboardStepping() {
        // 键盘步进：increase/decrease 按 stepSize 步进（模板方法公开可调）
        const s = makeSlider({ stepSize: 0.1 })
        compare(s.first.value, 0)
        s.first.increase()
        compare(s.first.value, 0.1, "first increase 步进 stepSize")
        s.first.increase()
        compare(s.first.value, 0.2)
        s.first.decrease()
        compare(s.first.value, 0.1, "first decrease 步进 stepSize")
        s.second.decrease()
        compare(s.second.value, 0.9, "second decrease 步进")
        s.second.increase()
        compare(s.second.value, 1)
    }

    function test_keyboardStepClamp() {
        // 键盘步进边界钳制：first 不能越过 second（模板钳制）
        const s = makeSlider({ stepSize: 0.1 })
        s.setValues(0.95, 1)
        s.first.increase()
        compare(s.first.value, 1, "first 钳到 second——可重合")
        s.first.increase()
        compare(s.first.value, 1, "越界停（不交叉）")
    }

    function test_programmaticNoSnap() {
        // 程序化赋值不吸附：snapMode/stepSize 下 setValues 值保持——
        // 吸附仅在模板拖动路径（setValue 无 snap）
        const s = makeSlider({ stepSize: 0.1, snapMode: RangeSlider.SnapAlways })
        s.setValues(0.23, 0.67)
        compare(s.first.value, 0.23, "程序化 first 不吸附")
        compare(s.second.value, 0.67, "程序化 second 不吸附")
    }

    function test_endpointClamp() {
        // 端点钳制：程序化写值模板钳制（first ∈ [from, second]、
        // second ∈ [first, to]——可重合不交叉）
        const s = makeSlider({})
        s.setValues(0.8, 0.8)
        compare(s.first.value, 0.8)
        compare(s.second.value, 0.8)
        s.first.value = 0.9
        compare(s.first.value, 0.8, "first 钳到 second——重合不交叉")
        s.second.value = 0.5
        compare(s.second.value, 0.8, "second 钳到 first——重合不交叉")
        s.second.value = 2
        compare(s.second.value, 1, "second 钳到 to")
        s.first.value = -1
        compare(s.first.value, 0, "first 钳到 from")
    }

    function test_invertedRange() {
        // 倒置范围（from > to）：位置反向、区间仍正向（模板保证
        // first.position <= second.position——数学恒等）
        const s = makeSlider({ from: 100, to: 0 })
        s.setValues(90, 10)
        // first = (90-100)/(0-100) = 0.1、second = 0.9（LTR visualPosition = position）
        const rb = rangeBox(s)
        compare(rb.x, 0.1 * 160)
        compare(rb.width, 160 * 0.8 + 40)
        compare(rb.x, s.first.handle.x)
        compare(rb.x + rb.width, s.second.handle.x + s.second.handle.width)
    }

    function test_handlePluggable() {
        // handle 插拔：替换 first.handle（模板 handle 插拔契约）——替换
        // 实例生效、second 默认不受影响
        const s = createTemporaryObject(sliderWithCustomHandle, root, {})
        verify(s.first.handle.objectName === "customHandle", "first handle 已替换")
        verify(s.second.handle !== null, "second handle 存在")
    }
}
