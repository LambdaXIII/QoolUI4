import QtQuick
import QtTest
import Qool
import Qool.Controls

// RangeSlider 三层结构测试（Qool.Controls/RangeSlider.qml +
// Qool.Controls/RangeHandle.qml——两者配套，单接缝同文件）
//
// 被测契约（外部行为与公开契约——不测内部实现）：
// - 默认状态自洽（implicit 80×25、color = Style.accent、两手柄值 0/1、
//   preferredHeight 收缩公式、rangeHandle/surface 存在）
// - 背景轨道：静态 Crystal（Style.text、恒常态高、垂直居中——不随交互变）
// - 前景几何（RangeHandle 布局施加）：surface.x = firstPosition − cutSize、
//   width = 区间宽 + 2×cutSize（尖角溢出）、中央直边区 = 区间（宽 − 高 =
//   区间宽——切角后）、y 垂直居中；值变化跟随
// - 重合退化：区间宽 0 → surface 宽 = 高（水晶菱形，无需特判）
// - 锁存窗口：任一值写入 → justMoved 500ms（双值触发）
// - 展开反馈：externalExpanded（= justMoved）→ surface 高 = 控件全高；
//   窗口落后回常态（动画关闭——即时）
// - 倒置范围（from > to）：位置反向、区间仍正向
// - 信号契约与换算：QML 信号可作函数调用触发处理器——firstMoved(pos)/
//   secondMoved(pos) 断言位置→值换算、rangeMoved(delta) 断言整体滑移
//   （两端同步平移、区间宽不变、边界钳制整体停）与端点钳制（行程内、
//   可重合不越界）
// - surface 替换最低要求：替换简单 Rectangle → 自动填充区间 × 高度
//   （布局由 RangeHandle 统一施加——宿主无需自算值→位置映射）
// - RangeHandle 独立实例化：位置绑定 x/width 跟随 firstPosition/
//   secondPosition
//
// 注：真实鼠标交互（分区判定、拖动触发、hover 反馈）不在自动化范围——
// 本批次环境合成鼠标事件对 Quick Controls 模板不可达（探针实测）；
// 信号载荷与换算结果经手动 emit 自动测；交互契约以 spec/示例页人工验收。
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

    // surface 替换组件（外观插拔最低要求——简单 Rectangle）
    Component {
        id: sliderWithRectSurface
        RangeSlider {
            width: 200
            height: 40
            animationEnabled: false
            rangeHandle: RangeHandle {
                surface: Rectangle {
                    objectName: "customSurface"
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
            animationEnabled: false
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

    // 测试基准：200×40 → preferredHeight = 40 - bound(3, 10, 25) = 30、
    // 控件高 = 40、行程 travel = availableWidth - 高 = 160、
    // 中心行程 [20, 180]；firstPosition = first.visualPosition * 160 + 20；
    // cutSize = 15；位置→值（from=0/to=1、padding 0）：
    // value = (位置 − 20) / 160

    function valueOf(pos) {
        return (pos - 20) / 160
    }

    function test_defaults() {
        const s = makeSlider({})
        compare(s.implicitWidth, 80)
        compare(s.implicitHeight, 25)
        compare(s.color, s.Style.accent)
        compare(s.first.value, 0)
        compare(s.second.value, 1)
        compare(s.preferredHeight, 30)
        verify(s.rangeHandle !== null, "rangeHandle 存在")
        verify(s.rangeHandle.surface !== null, "surface 存在（默认 Crystal）")
        compare(s.rangeHandle.expanded, false)
        compare(s.rangeHandle.surfaceHeight, 30)
        compare(s.rangeHandle.midPosition, (s.firstPosition + s.secondPosition) / 2)
    }

    function test_backgroundTrack() {
        // 背景 = 静态 Crystal 轨道（text 色、恒常态高、垂直居中）
        const s = makeSlider({})
        const track = findChild(s.background, "track")
        verify(track !== null, "轨道存在")
        compare(track.height, 30)
        compare(track.y, 5)
        compare(track.color, s.Style.text)
        // 轨道静态——值写入（justMoved）不改变轨道高度
        s.setValues(0.25, 0.75)
        compare(track.height, 30)
        compare(track.y, 5)
    }

    function test_foregroundGeometry() {
        // surface 布局：x = firstPosition − cutSize、宽 = 区间宽 + 2×cut
        // （尖角溢出）、y 垂直居中；常态（锁存窗口落）时中央直边区 = 区间
        // （宽 − 高 = 区间宽——切角后）
        const s = makeSlider({})
        const surf = s.rangeHandle.surface
        s.setValues(0.25, 0.75)
        const firstPos = 0.25 * 160 + 20 // 60
        const secondPos = 0.75 * 160 + 20 // 140
        // 值写入 → justMoved 锁存 → 展开态（x/width 与展开无关——先断言）
        compare(surf.x, firstPos - 15)
        compare(surf.width, (secondPos - firstPos) + 30)
        compare(surf.height, 40, "写入即展开")
        compare(surf.y, 0)
        compare(surf.color, s.color)
        wait(600)
        // 常态几何：高 = preferredHeight、垂直居中、中央直边区 = 区间
        compare(surf.height, 30)
        compare(surf.y, (40 - 30) / 2)
        compare(surf.width - surf.height, secondPos - firstPos)
        // 值变化跟随（x/width 与展开无关）
        s.setValues(0.4, 0.6)
        compare(surf.x, 0.4 * 160 + 20 - 15)
        compare(surf.width, (0.6 - 0.4) * 160 + 30)
        s.first.value = 0.5
        compare(surf.x, 0.5 * 160 + 20 - 15)
    }

    function test_degenerateDiamond() {
        // 重合退化：两端点重合 → surface 宽 = 高（水晶菱形——cut 自动
        // 合理化，无需特判）；锁存窗口落后断言常态
        const s = makeSlider({})
        s.setValues(0.5, 0.5)
        const surf = s.rangeHandle.surface
        compare(surf.x, 100 - 15)
        compare(surf.width, 30)
        wait(600)
        compare(surf.width, 30)
        compare(surf.height, 30)
        compare(surf.width, surf.height, "重合 = 菱形")
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

    function test_expandFeedback() {
        // 值写入 → surface 展开到控件全高（常态 = preferredHeight）——
        // 锁存窗口内保持、窗口落后回常态（动画关闭——即时）
        const s = makeSlider({})
        const surf = s.rangeHandle.surface
        compare(surf.height, 30)
        s.setValues(0.25, 0.75)
        compare(surf.height, 40, "justMoved 展开")
        wait(600)
        compare(surf.height, 30, "窗口落后回常态")
    }

    function test_invertedRange() {
        // 倒置范围（from > to）：位置反向、区间仍正向（模板保证
        // first.visualPosition <= second.visualPosition——数学恒等）
        const s = makeSlider({ from: 100, to: 0 })
        s.setValues(90, 10)
        const surf = s.rangeHandle.surface
        // first = (90-100)/(0-100) = 0.1、second = 0.9
        compare(surf.x, 0.1 * 160 + 20 - 15)
        compare(surf.x + surf.width, 0.9 * 160 + 20 + 15)
        verify(surf.width > 30, "倒置区间宽正向")
    }

    function test_signalValueConversion() {
        // 信号载荷与换算：firstMoved/secondMoved → 位置→值换算
        const s = makeSlider({})
        s.setValues(0.25, 0.75)
        // firstMoved(pos) —— 位置 → first 值（second 不动）
        s.rangeHandle.firstMoved(60)
        compare(s.first.value, valueOf(60))
        compare(s.second.value, 0.75)
        s.rangeHandle.firstMoved(100)
        compare(s.first.value, valueOf(100))
        compare(s.second.value, 0.75, "first 拖动不影响 second")
        // secondMoved(pos) —— second 值（first 不动）
        s.rangeHandle.secondMoved(140)
        compare(s.second.value, valueOf(140))
        compare(s.first.value, valueOf(100), "second 拖动不影响 first")
        s.rangeHandle.secondMoved(180)
        compare(s.second.value, 1)
    }

    function test_signalDegenerateCoincide() {
        // 端点重合契约：拖到对方端点位置 → 值相等（退化菱形）；行程端点
        // 位置 → 值 = from/to。注：端点钳制（拖动路径内、防越界/交叉）属
        // 交互层——真实鼠标路径人工验收（spec），信号载荷本身原样换算。
        const s = makeSlider({})
        s.setValues(0.25, 0.75)
        // first 拖到 second 位置（合法载荷）→ 重合（退化菱形）
        s.rangeHandle.firstMoved(140)
        compare(s.first.value, 0.75)
        compare(s.first.value, s.second.value, "first 重合 second")
        // second 拖到行程终点 → 分离
        s.rangeHandle.secondMoved(180)
        compare(s.second.value, 1)
        // first 拖回行程起点 → from
        s.rangeHandle.firstMoved(20)
        compare(s.first.value, 0)
        // second 拖回 → 正常换算（载荷不越 first）
        s.rangeHandle.secondMoved(60)
        compare(s.second.value, 0.25)
        verify(s.second.value > s.first.value, "区间正向")
    }

    function test_rangeDragOverallShift() {
        // 整体滑移：rangeMoved(delta) → 两端同步平移、区间宽不变、
        // 边界钳制整体停
        const s = makeSlider({})
        s.setValues(0.25, 0.75)
        // 正向位移 16px = 0.1 值
        s.rangeHandle.rangeMoved(16)
        compare(s.first.value, 0.25 + 16 / 160)
        compare(s.second.value, 0.75 + 16 / 160)
        compare(s.second.value - s.first.value, 0.5, "区间宽不变")
        // 负向位移
        s.rangeHandle.rangeMoved(-32)
        compare(s.first.value, 0.25 - 16 / 160)
        compare(s.second.value, 0.75 - 16 / 160)
        compare(s.second.value - s.first.value, 0.5, "区间宽不变")
        // 边界钳制整体停：正向越界 → 整体停（两端都停、区间宽不变）
        s.setValues(0.25, 0.75)
        s.rangeHandle.rangeMoved(1000)
        compare(s.first.value, 0.5)
        compare(s.second.value, 1)
        compare(s.second.value - s.first.value, 0.5, "边界整体停——区间宽不变")
        // 负向越界 → 整体停
        s.setValues(0.25, 0.75)
        s.rangeHandle.rangeMoved(-1000)
        compare(s.first.value, 0)
        compare(s.second.value, 0.5)
        compare(s.second.value - s.first.value, 0.5, "边界整体停——区间宽不变")
    }

    function test_surfaceReplacement() {
        // surface 替换最低要求：任意简单 Item（Rectangle）替换 → 自动
        // 填充正确区间 × 高度（布局由 RangeHandle 统一施加——宿主无需
        // 自算值→位置映射）
        const s = createTemporaryObject(sliderWithRectSurface, root, {})
        const rect = s.rangeHandle.surface
        verify(rect !== null, "替换 surface 存在")
        verify(rect.objectName === "customSurface", "surface 已被替换")
        s.setValues(0.25, 0.75)
        wait(600) // 锁存窗口落——断言常态几何
        compare(rect.x, 0.25 * 160 + 20 - 15)
        compare(rect.width, (0.75 - 0.25) * 160 + 30)
        compare(rect.height, 30)
        compare(rect.y, (40 - 30) / 2)
        compare(rect.color, s.color)
        // 值变化跟随（x/width 与展开无关）
        s.setValues(0.4, 0.6)
        compare(rect.x, 0.4 * 160 + 20 - 15)
        compare(rect.width, (0.6 - 0.4) * 160 + 30)
    }

    function test_rangeHandleStandalone() {
        // RangeHandle 独立实例化：位置绑定 x/width 跟随 firstPosition/
        // secondPosition（surface 布局同样施加）
        const h = createTemporaryObject(handleComp, root, {})
        h.firstPosition = 60
        h.secondPosition = 140
        compare(h.surface.x, 60 - 15)
        compare(h.surface.width, 80 + 30)
        compare(h.surface.height, 30)
        compare(h.surface.y, (40 - 30) / 2)
        compare(h.midPosition, 100)
        compare(h.surfaceHeight, 30)
        // 位置变化跟随
        h.firstPosition = 80
        compare(h.surface.x, 80 - 15)
        compare(h.surface.width, 60 + 30)
        // 外部展开源（externalExpanded）→ surface 高 = 控件全高
        h.externalExpanded = true
        compare(h.surface.height, 40)
        compare(h.surface.y, 0)
        // 展开源释放 → 回常态
        h.externalExpanded = false
        compare(h.surface.height, 30)
        compare(h.surface.y, 5)
    }
}
