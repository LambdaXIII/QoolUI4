import QtQuick
import QtTest
import Qool
import Qool.Controls

// RangeSlider 组件测试（Qool.Controls/RangeSlider.qml）
//
// 被测契约：
// - 默认状态自洽（implicit 80×25、color = Style.accent、两手柄值 0、
//   preferredHeight 收缩公式）
// - 手柄 = HalfCrystal 三角形（first direction W / second direction E——
//   尖角朝外、平边相对夹已选段）；段色采样（first = Style.text、
//   second = color）
// - 已选段几何（公开视觉契约）：平切矩形——x/右缘 = 两手柄中心线、
//   高 = preferredHeight；值变化跟随
// - 锁存窗口：任一值被写入（无论谁写）→ justMoved 500ms → 手柄展开
//   （animationEnabled 关闭时即时）→ 窗口落回常态
// - 倒置范围（from > to）：位置反向、已选段仍正向（first 中心 <= second 中心）
// - 值相等退化：已选段宽 0（不可见）
//
// 注：模板交互（点击跳转最近手柄/拖动/键盘）为官方行为（接口兼容承诺，Qt
// 保证）——不在此测：本批次环境鼠标合成事件对 Quick Controls 模板不可达
// （探针实测官方 T.RangeSlider 与 Qool Slider 点击/拖动均无效果——环境限制，
// 非组件缺陷）。交互回归靠示例页人工验收。
//
// 内部对象经 objectName 读取（组件内部对象零暴露原则的测试例外——
// 几何/手柄契约是公开视觉行为）。
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例；
// 动画统一关闭（animationEnabled: false）——展开断言即时。

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

    // —— 内部对象读取辅助（objectName 定位 + children 遍历）——
    function findChild(item, name) {
        if (item === null || item === undefined)
            return null
        for (let i = 0; i < item.children.length; ++i) {
            if (item.children[i].objectName === name)
                return item.children[i]
        }
        return null
    }

    function makeSlider(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(sliderComp, root, props)
    }

    // 测试基准：200×40 → pH = 40 - bound(3, 10, 25) = 30、h = 40、
    // 行程 = availableWidth - h = 160、中心行程 [20, 180]
    // firstCenterX = first.visualPosition * 160 + 20

    function test_defaults() {
        const s = makeSlider({})
        compare(s.implicitWidth, 80)
        compare(s.implicitHeight, 25)
        compare(s.color, s.Style.accent)
        compare(s.first.value, 0)
        compare(s.second.value, 1)
        compare(s.preferredHeight, 30)
        verify(s.first.handle !== null, "first.handle 存在")
        verify(s.second.handle !== null, "second.handle 存在")
    }

    function test_handleShapeAndColor() {
        // 手柄 = HalfCrystal 三角形（W/E）+ 段色采样（first text / second color）
        const s = makeSlider({})
        s.setValues(0.25, 0.75)
        const fh = s.first.handle
        const sh = s.second.handle
        const fc = findChild(fh, "firstCrystal")
        const sc = findChild(sh, "secondCrystal")
        verify(fc !== null, "first 手柄 HalfCrystal 存在")
        verify(sc !== null, "second 手柄 HalfCrystal 存在")
        compare(fc.direction, Qore.W)
        compare(sc.direction, Qore.E)
        compare(fc.color, s.Style.text)
        compare(sc.color, s.color)
    }

    function test_handleAndSelectionGeometry() {
        // 手柄定位（中心行程公式）+ 已选段 = 两手柄中心线之间（平切矩形）
        const s = makeSlider({})
        s.setValues(0.25, 0.75)
        // 手柄中心线：pos * 160 + 20
        const firstCenter = 0.25 * 160 + 20 // 60
        const secondCenter = 0.75 * 160 + 20 // 140
        compare(s.first.handle.x, 0.25 * 160)
        compare(s.first.handle.width, 40)
        compare(s.first.handle.x + s.first.handle.width / 2, firstCenter)
        const sel = findChild(s.background, "selection")
        verify(sel !== null, "已选段存在")
        compare(sel.x, firstCenter)
        compare(sel.x + sel.width, secondCenter)
        compare(sel.y, (40 - 30) / 2)
        compare(sel.height, 30)
        compare(sel.color, s.color)
        // 轨道 = 基底六边形（text 色、恒常态高、垂直居中）
        const track = s.background.children[0]
        compare(track.height, 30)
        compare(track.y, 5)
        compare(track.color, s.Style.text)
    }

    function test_selectionFollowsValues() {
        // 值变化 → 已选段跟随（多值点——公开视觉契约）
        const s = makeSlider({})
        const sel = findChild(s.background, "selection")
        s.setValues(0.1, 0.9)
        compare(sel.x, 0.1 * 160 + 20)
        compare(sel.width, (0.9 - 0.1) * 160)
        s.setValues(0.4, 0.6)
        compare(sel.x, 0.4 * 160 + 20)
        compare(sel.width, (0.6 - 0.4) * 160)
        s.first.value = 0.5
        compare(sel.x, 0.5 * 160 + 20)
    }

    function test_justMovedLatch() {
        // 任一值被写入 → justMoved 锁存 500ms；无写入时不锁存
        const s = makeSlider({})
        compare(s.justMoved, false)
        s.first.value = 0.5
        verify(s.justMoved, "first 写入锁存")
        wait(600)
        verify(!s.justMoved, "窗口落")
        s.second.value = 0.9
        verify(s.justMoved, "second 写入锁存")
        wait(600)
        verify(!s.justMoved, "窗口落")
    }

    function test_handleExpandFeedback() {
        // 值写入 → 手柄展开到控件全高（常态 = preferredHeight）——锁存窗口内
        // 保持、窗口落后回常态（动画关闭——即时）
        const s = makeSlider({})
        const fc = findChild(s.first.handle, "firstCrystal")
        const sc = findChild(s.second.handle, "secondCrystal")
        compare(fc.height, 30)
        compare(sc.height, 30)
        s.setValues(0.25, 0.75)
        compare(fc.height, 40, "first 展开")
        compare(sc.height, 40, "second 展开")
        wait(600)
        compare(fc.height, 30, "first 回常态")
        compare(sc.height, 30, "second 回常态")
    }

    function test_invertedRange() {
        // 倒置范围（from > to）：位置反向、已选段仍正向（模板保证
        // first.position <= second.position——数学恒等，见组件头注释）
        const s = makeSlider({ from: 100, to: 0 })
        s.setValues(90, 10)
        const sel = findChild(s.background, "selection")
        // first = (90-100)/(0-100) = 0.1、second = 0.9
        compare(sel.x, 0.1 * 160 + 20)
        compare(sel.x + sel.width, 0.9 * 160 + 20)
        verify(sel.width > 0, "倒置已选段宽度正向")
    }

    function test_equalValuesDegenerate() {
        // 值相等：已选段宽 0（不可见）——两三角形平边相对重合（水晶菱形）
        const s = makeSlider({})
        s.setValues(0.5, 0.5)
        const sel = findChild(s.background, "selection")
        compare(sel.width, 0)
    }
}
