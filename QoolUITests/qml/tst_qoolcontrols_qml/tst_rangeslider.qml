import QtQuick
import QtTest
import Qool
import Qool.Controls

// RangeSlider 三层结构测试（Qool.Controls/RangeSlider.qml +
// Qool.Controls/RangeHandle.qml——两者配套，单接缝同文件）
//
// 被测契约（外部行为与公开契约——不测内部实现）：
// - 默认状态自洽（implicit 80×25、color = Style.accent、两手柄值 0/1、
//   rangeHandle/surface 存在、两端锁存初始 false）
// - 背景轨道：静态 Crystal（Style.text、常态收缩、居中——不随交互变）
// - 区间盒几何（值→位置映射）：rangeHandle.x/width = 区间盒（x =
//   availableWidth * position、宽 = availableWidth * 区间宽）；surface
//   自行 fill（anchors.fill），内部 Crystal 常态收缩 crystalShrinkSize、
//   展开占满
// - 锁存分化：first/second 独立锁存窗口（500ms，写入即触发、独立回落）
// - 展开反馈：任一锁存或拖动按下（down）→ Crystal 占满区间盒；窗口落回
//   常态收缩（动画关闭——即时）
// - 倒置范围（from > to）：位置反向、区间仍正向
// - 信号契约与换算：QML 信号可作函数调用触发处理器——wannaMoveFirstX(dx)/
//   wannaMoveSecondX(dx) 断言位移→值增量换算与端点钳制（值域内、可重合
//   不交叉）、wannaMoveRangeX(dx) 断言整体滑移（两端同步平移、区间宽不变、
//   边界钳制整体停）
// - 三区几何：独立实例化 RangeHandle 三区物理分区（左/右端点热区 +
//   中段行程区）、热区扩展、光标 alias
// - surface 替换最低要求：替换简单 Rectangle（自行 anchors.fill）→ 填充
//   区间盒（布局由 surface 自负——RangeHandle 不再施加）
// - RangeHandle 独立实例化：几何/分区/信号可独立使用
//
// 注：真实鼠标交互（分区命中、拖动触发、hover 反馈）不在自动化范围——
// 本批次环境合成鼠标事件对 Quick Controls 模板不可达（探针实测）；
// 信号载荷与换算结果经手动 emit 自动测；交互契约以 spec/示例页人工验收。
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例；
// 动画统一关闭（animationEnabled: false）——展开断言即时。
//
// 测试基准：200×40 → crystalShrinkSize = bound(3, 10, 25) = 10、
// availableWidth = 200（padding 0）；区间盒 x = 200 * position；
// 位移→值 1px = 1/200（from=0/to=1）。

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

    // surface 替换组件（外观插拔最低要求——简单 Rectangle 自行 fill）
    Component {
        id: sliderWithRectSurface
        RangeSlider {
            width: 200
            height: 40
            animationEnabled: false
            rangeHandle: RangeHandle {
                surface: Rectangle {
                    objectName: "customSurface"
                    anchors.fill: parent
                }
            }
        }
    }

    // RangeHandle 独立实例化（脱离 RangeSlider 自建滑块场景）
    Component {
        id: handleComp
        RangeHandle {
            width: 200
            height: 40
        }
    }

    function makeSlider(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(sliderComp, root, props)
    }

    // —— 内部对象读取辅助（objectName 定位——组件内部对象零暴露原则的
    // 测试例外：轨道静态性是公开视觉契约）——
    function findChild(item, name) {
        if (item === null || item === undefined)
            return null
        for (let i = 0; i < item.children.length; ++i) {
            if (item.children[i].objectName === name)
                return item.children[i]
        }
        return null
    }

    function test_defaults() {
        const s = makeSlider({})
        compare(s.implicitWidth, 80)
        compare(s.implicitHeight, 25)
        compare(s.color, s.Style.accent)
        compare(s.first.value, 0)
        compare(s.second.value, 1)
        compare(s.firstJustMoved, false)
        compare(s.secondJustMoved, false)
        verify(s.rangeHandle !== null, "rangeHandle 存在")
        verify(s.rangeHandle.surface !== null, "surface 存在")
        compare(s.rangeHandle.down, false)
        // 默认区间 = 全宽（first=0、second=1）
        compare(s.rangeHandle.x, 0)
        compare(s.rangeHandle.width, 200)
    }

    function test_backgroundTrack() {
        // 背景 = 静态 Crystal 轨道（bgColor 色、尖角外溢、居中——不随交互变）
        const s = makeSlider({})
        const track = findChild(s.background, "track")
        verify(track !== null, "轨道存在")
        // 尖角外溢：width = 控件宽 + 自身高 = 200 + 30，居中 → 尖点外溢 h/2
        compare(track.width, 200 + 30)
        compare(track.height, 40 - 10)
        compare(track.x, (200 - (200 + 30)) / 2, "水平居中（尖角外溢两侧）")
        compare(track.y, (40 - (40 - 10)) / 2, "垂直居中")
        compare(track.color, Qt.alpha(s.bgColor, 0.75), "轨道半透明 bgColor")
        // 轨道静态——值写入（justMoved）不改变轨道几何
        s.setValues(0.25, 0.75)
        compare(track.width, 230)
        compare(track.height, 30)
        compare(track.x, -15)
        compare(track.y, 5)
    }

    function test_rangeBoxGeometry() {
        // 区间盒（值→位置映射）：rangeHandle.x/width 跟随值；surface 自行
        // fill 区间盒；Crystal 常态收缩、展开占满
        const s = makeSlider({})
        const surf = s.rangeHandle.surface
        const crystal = surf.children[0] // 默认 surface 内的 Crystal
        verify(crystal !== undefined, "默认 surface 内含 Crystal")
        // 初始（first=0、second=1）：区间盒 = 全宽
        compare(s.rangeHandle.x, 0)
        compare(s.rangeHandle.width, 200)
        compare(s.rangeHandle.height, 40)
        compare(surf.x, 0, "surface fill 区间盒")
        compare(surf.width, 200)
        // 前景尖角外溢：width = 区间宽 + 自身高 − 常态收缩
        compare(crystal.width, 200 + 30 - 10, "常态收缩+尖角外溢")
        compare(crystal.height, 40 - 10)
        // 写入 → 区间盒跟随 + 展开占满（直边区 = 区间宽、尖角外溢随高度）
        s.setValues(0.25, 0.75)
        compare(s.rangeHandle.x, 0.25 * 200)
        compare(s.rangeHandle.width, 0.5 * 200)
        compare(surf.x, 0)
        compare(surf.width, 100)
        compare(crystal.width, 100 + 40, "展开占满区间盒+尖角外溢")
        compare(crystal.height, 40, "展开占满区间盒")
        // 锁存窗口落 → 回常态收缩（直边区仍 = 区间宽、外溢量随高度缩小）
        wait(600)
        compare(crystal.width, 100 + 30 - 10, "常态收缩")
        compare(crystal.height, 40 - 10)
        // 值变化跟随（区间盒与展开无关）
        s.setValues(0.4, 0.6)
        compare(s.rangeHandle.x, 0.4 * 200)
        compare(s.rangeHandle.width, 0.2 * 200)
    }

    function test_justMovedLatchSplit() {
        // 两端锁存独立：写入一端只锁存该端、独立回落
        const s = makeSlider({})
        s.first.value = 0.5
        verify(s.firstJustMoved, "first 写入锁存")
        verify(!s.secondJustMoved, "second 未动不锁存")
        wait(600)
        verify(!s.firstJustMoved, "first 窗口落")
        s.second.value = 0.9
        verify(s.secondJustMoved, "second 写入锁存")
        verify(!s.firstJustMoved, "first 独立不受影响")
        wait(600)
        verify(!s.secondJustMoved, "second 窗口落")
    }

    function test_expandFeedback() {
        // 值写入 → Crystal 展开占满；窗口落后回常态（动画关闭——即时）
        const s = makeSlider({})
        const surf = s.rangeHandle.surface
        const crystal = surf.children[0]
        compare(crystal.height, 30, "常态收缩")
        s.setValues(0.25, 0.75)
        compare(crystal.height, 40, "锁存展开")
        wait(600)
        compare(crystal.height, 30, "窗口落后回常态")
    }

    function test_invertedRange() {
        // 倒置范围（from > to）：位置反向、区间仍正向（模板保证
        // first.position <= second.position——数学恒等）
        const s = makeSlider({ from: 100, to: 0 })
        s.setValues(90, 10)
        // first = (90-100)/(0-100) = 0.1、second = 0.9
        compare(s.rangeHandle.x, 0.1 * 200)
        compare(s.rangeHandle.x + s.rangeHandle.width, 0.9 * 200)
        compare(s.rangeHandle.width, 0.8 * 200)
    }

    function test_firstDragConversion() {
        // wannaMoveFirstX(dx) —— 位移 → first 值增量（second 不动）、
        // 钳制 [from, second]
        const s = makeSlider({})
        s.setValues(0.25, 0.75)
        s.rangeHandle.wannaMoveFirstX(20)
        compare(s.first.value, 0.25 + 20 / 200)
        compare(s.second.value, 0.75, "first 拖动不影响 second")
        s.rangeHandle.wannaMoveFirstX(-40)
        compare(s.first.value, 0.25 - 20 / 200)
        // 钳制：正向拖过 second → 重合退化（不交叉）
        s.setValues(0.25, 0.75)
        s.rangeHandle.wannaMoveFirstX(1000)
        compare(s.first.value, 0.75, "first 钳到 second——重合")
        // 钳制：负向拖出 from → 停在 from
        s.rangeHandle.wannaMoveFirstX(-1000)
        compare(s.first.value, 0, "first 钳到 from")
    }

    function test_secondDragConversion() {
        // wannaMoveSecondX(dx) —— 位移 → second 值增量（first 不动）、
        // 钳制 [first, to]
        const s = makeSlider({})
        s.setValues(0.25, 0.75)
        s.rangeHandle.wannaMoveSecondX(20)
        compare(s.second.value, 0.75 + 20 / 200)
        compare(s.first.value, 0.25, "second 拖动不影响 first")
        s.rangeHandle.wannaMoveSecondX(-40)
        compare(s.second.value, 0.75 - 20 / 200)
        // 钳制：负向拖过 first → 重合退化（不交叉）
        s.setValues(0.25, 0.75)
        s.rangeHandle.wannaMoveSecondX(-1000)
        compare(s.second.value, 0.25, "second 钳到 first——重合")
        // 钳制：正向拖出 to → 停在 to
        s.rangeHandle.wannaMoveSecondX(1000)
        compare(s.second.value, 1, "second 钳到 to")
    }

    function test_rangeDragOverallShift() {
        // 整体滑移：wannaMoveRangeX(dx) → 两端同步平移、区间宽不变、
        // 边界钳制整体停
        const s = makeSlider({})
        s.setValues(0.25, 0.75)
        // 正向位移 20px = 0.1 值
        s.rangeHandle.wannaMoveRangeX(20)
        compare(s.first.value, 0.25 + 20 / 200)
        compare(s.second.value, 0.75 + 20 / 200)
        compare(s.second.value - s.first.value, 0.5, "区间宽不变")
        // 负向位移
        s.rangeHandle.wannaMoveRangeX(-40)
        compare(s.first.value, 0.25 - 20 / 200)
        compare(s.second.value, 0.75 - 20 / 200)
        compare(s.second.value - s.first.value, 0.5, "区间宽不变")
        // 边界钳制整体停：正向越界 → 整体停（两端都停、区间宽不变）
        s.setValues(0.25, 0.75)
        s.rangeHandle.wannaMoveRangeX(1000)
        compare(s.first.value, 0.5)
        compare(s.second.value, 1)
        compare(s.second.value - s.first.value, 0.5, "边界整体停——区间宽不变")
        // 负向越界 → 整体停
        s.setValues(0.25, 0.75)
        s.rangeHandle.wannaMoveRangeX(-1000)
        compare(s.first.value, 0)
        compare(s.second.value, 0.5)
        compare(s.second.value - s.first.value, 0.5, "边界整体停——区间宽不变")
    }

    function test_surfaceReplacement() {
        // surface 替换最低要求：任意简单 Item（Rectangle 自行 fill）替换 →
        // 填充区间盒（布局由 surface 自负——RangeHandle 不施加）
        const s = createTemporaryObject(sliderWithRectSurface, root, {})
        const rect = s.rangeHandle.surface
        verify(rect !== null, "替换 surface 存在")
        verify(rect.objectName === "customSurface", "surface 已被替换")
        s.setValues(0.25, 0.75)
        compare(s.rangeHandle.x, 50)
        compare(s.rangeHandle.width, 100)
        compare(rect.x, 0, "fill 区间盒内部")
        compare(rect.width, 100)
        compare(rect.height, 40)
        // 值变化跟随
        s.setValues(0.4, 0.6)
        compare(s.rangeHandle.x, 80)
        compare(s.rangeHandle.width, 40)
        compare(rect.width, 40)
    }

    function test_rangeHandleStandalone() {
        // RangeHandle 独立实例化：surface 默认 fill、三区存在、信号可发射
        const h = createTemporaryObject(handleComp, root, {})
        compare(h.width, 200)
        compare(h.height, 40)
        compare(h.down, false)
        verify(h.surface !== null, "默认 surface 存在")
        compare(h.surface.width, 200, "默认 surface fill 本组件")
        compare(h.surface.height, 40)
        compare(h.firstCursorShape, Qt.SplitHCursor, "左区光标默认")
        compare(h.secondCursorShape, Qt.SplitHCursor, "右区光标默认")
        // 信号可发射（无接收者——独立场景宿主自连）
        h.wannaMoveFirstX(10)
        h.wannaMoveSecondX(10)
        h.wannaMoveRangeX(10)
    }

    function test_zoneGeometry() {
        // 三区物理分区（独立实例化）：height 40 → handleHSpace 20、
        // center [20, 180]、left [−2, 20]、right [180, 202]（ext 2）；
        // 热区扩展仅改变左右区宽度（left 左溢、right 右缘外扩——右区左缘
        // 固定 = width − handleHSpace，不随 ext 变）
        const h = createTemporaryObject(handleComp, root, {})
        const zones = []
        for (let i = 0; i < h.children.length; ++i) {
            if (h.children[i].cursorShape !== undefined)
                zones.push(h.children[i])
        }
        compare(zones.length, 3, "三个拖动区")
        zones.sort((a, b) => a.x - b.x)
        compare(zones[0].x, -2)
        compare(zones[0].width, 20 + 2)
        compare(zones[1].x, 20)
        compare(zones[1].width, 160)
        compare(zones[2].x, 180)
        compare(zones[2].width, 20 + 2)
        // 热区扩展：左右区宽增、左区左溢、右区右缘外扩（左缘不动）
        h.firstMouseZoneExtension = 6
        h.secondMouseZoneExtension = 6
        const zones2 = []
        for (let i = 0; i < h.children.length; ++i) {
            if (h.children[i].cursorShape !== undefined)
                zones2.push(h.children[i])
        }
        zones2.sort((a, b) => a.x - b.x)
        compare(zones2[0].x, -6, "左区左溢")
        compare(zones2[0].width, 26)
        compare(zones2[2].x, 180, "右区左缘不动")
        compare(zones2[2].width, 26)
    }
}
