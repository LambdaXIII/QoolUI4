import QtQuick
import QtTest
import Qool
import Qool.Controls

// RangeSlider 测试（Qool.Controls/RangeSlider.qml——T.RangeSlider 模板 +
// 默认透明 handle 激活模板交互 + Crystal 轨道 + surface 外观插拔件）
//
// 被测契约（外部行为与公开契约——不测内部实现）：
// - 默认状态自洽（implicit 80×25、color = Style.accent、两手柄值 0/1、
//   surface 存在、first/second handle 存在、两端锁存初始 false）
// - 背景轨道：静态 Crystal（常态收缩、居中——不随交互变）
// - 区间盒几何（值→位置映射）：surface.x/width = 区间盒（x =
//   availableWidth * position + leftPadding、宽 = availableWidth * 区间宽）
// - handle 中心对齐：first/second handle 中心 = 值位置（x =
//   leftPadding + availableWidth * position − w/2；w = h = availableHeight）
// - 锁存分化：first/second 独立锁存窗口（500ms，写入即触发、独立回落）
// - 展开反馈：任一锁存 → Crystal 占满区间盒；窗口落回常态收缩
// - 键盘步进：first/second 的 increase()/decrease() 按 stepSize 步进
//   （模板方法——键盘路径公开可调）
// - 程序化赋值不吸附：snapMode/stepSize 下 setValues 不吸附（模板 setValue
//   无 snap——吸附仅在模板拖动路径生效）
// - 端点钳制：程序化写值模板钳制（first ∈ [from, second]、second ∈
//   [first, to]——可重合不交叉）
// - 倒置范围（from > to）：位置反向、区间仍正向
// - surface 替换最低要求：替换简单 Rectangle（自行 anchors.fill）→ 填充
//   区间盒（几何由 Binding 组施加——替换实例同样受控）
// - handle 插拔：替换 first.handle（模板 handle 插拔契约）
//
// 注：真实鼠标交互（模板拖动、snap/live 拖动路径、pressed/hovered 反馈）
// 不在自动化范围——合成鼠标事件对 Quick Controls 模板不可达（探针实测），
// 且模板 pressed/hovered 为只读属性（不可设值驱动）；交互契约以
// spec/示例页人工验收。
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例；
// 动画统一关闭（animationEnabled: false）——展开断言即时。
//
// 测试基准：200×40 → crystalShrinkSize = bound(3, 10, 25) = 10、
// availableWidth = 200（padding 0）；区间盒 x = 200 * position；
// handle w = h = availableHeight = 40。

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
            surface: Rectangle {
                objectName: "customSurface"
                anchors.fill: parent
            }
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
        verify(s.surface !== null, "surface 存在")
        verify(s.first.handle !== null, "first handle 存在")
        verify(s.second.handle !== null, "second handle 存在")
        // 默认区间 = 全宽（first=0、second=1）
        compare(s.surface.x, 0)
        compare(s.surface.width, 200)
    }

    function test_backgroundTrack() {
        // 背景 = 静态 Crystal 轨道（backgroundColor 色、尖角外溢、居中——不随交互变）
        const s = makeSlider({})
        const track = findChild(s.background, "track")
        verify(track !== null, "轨道存在")
        // 尖角外溢：width = 控件宽 + 自身高 = 200 + 30，居中 → 尖点外溢 h/2
        compare(track.width, 200 + 30)
        compare(track.height, 40 - 10)
        compare(track.x, (200 - (200 + 30)) / 2, "水平居中（尖角外溢两侧）")
        compare(track.y, (40 - (40 - 10)) / 2, "垂直居中")
        compare(track.color, Qt.alpha(s.backgroundColor, 0.75), "轨道半透明 backgroundColor")
        // 轨道静态——值写入（justMoved）不改变轨道几何
        s.setValues(0.25, 0.75)
        compare(track.width, 230)
        compare(track.height, 30)
        compare(track.x, -15)
        compare(track.y, 5)
    }

    function test_rangeBoxGeometry() {
        // 区间盒（值→位置映射）：surface.x/width 跟随值；Crystal 常态收缩、
        // 展开占满
        const s = makeSlider({})
        const surf = s.surface
        const crystal = surf.children[0] // 默认 surface 内的 Crystal
        verify(crystal !== undefined, "默认 surface 内含 Crystal")
        // 初始（first=0、second=1）：区间盒 = 全宽
        compare(s.surface.x, 0)
        compare(s.surface.width, 200)
        compare(s.surface.height, 40)
        // 前景尖角外溢：width = 区间宽 + 自身高（直边区 = 区间宽恒等——
        // 收缩只体现在高度维度）
        compare(crystal.width, 200 + 30, "常态尖角外溢")
        compare(crystal.height, 40 - 10)
        // 写入 → 区间盒跟随 + 展开占满（直边区 = 区间宽、尖角外溢随高度）
        s.setValues(0.25, 0.75)
        compare(s.surface.x, 0.25 * 200)
        compare(s.surface.width, 0.5 * 200)
        compare(crystal.width, 100 + 40, "展开占满区间盒+尖角外溢")
        compare(crystal.height, 40, "展开占满区间盒")
        // 锁存窗口落 → 回常态（直边区仍 = 区间宽、外溢量随高度缩小）
        wait(600)
        compare(crystal.width, 100 + 30, "常态尖角外溢")
        compare(crystal.height, 40 - 10)
        // 值变化跟随（区间盒与展开无关）
        s.setValues(0.4, 0.6)
        compare(s.surface.x, 0.4 * 200)
        compare(s.surface.width, 0.2 * 200)
    }

    function test_handleCenterAlignment() {
        // handle 中心对齐值位置：x = leftPadding + availableWidth * position
        // − w/2；w = h = availableHeight（响应 padding 的正方形）
        const s = makeSlider({})
        const fh = s.first.handle
        const sh = s.second.handle
        compare(fh.width, 40, "w = availableHeight")
        compare(fh.height, 40, "h = availableHeight")
        compare(fh.y, 0, "y = topPadding（padding 0）")
        compare(fh.x, 0 - 20, "position 0 → 中心 = 0（左半溢出 padding）")
        compare(fh.x + fh.width / 2, 0, "first handle 中心 = 值位置（surface 左端点）")
        compare(sh.x, 200 - 20, "second position 1 → 中心 = 200")
        compare(sh.x + sh.width / 2, 200, "second handle 中心 = 值位置（surface 右端点）")
        // 写值 → handle 跟随（中心始终 = 值位置）
        s.setValues(0.25, 0.75)
        compare(fh.x + fh.width / 2, 0.25 * 200, "first 中心跟随")
        compare(sh.x + sh.width / 2, 0.75 * 200, "second 中心跟随")
        // 中心与 surface 端点同源（无偏移）
        compare(fh.x + fh.width / 2, s.surface.x, "handle 中心 = surface 端点")
        compare(sh.x + sh.width / 2, s.surface.x + s.surface.width, "second 中心 = surface 右端点")
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
        const surf = s.surface
        const crystal = surf.children[0]
        compare(crystal.height, 30, "常态收缩")
        s.setValues(0.25, 0.75)
        compare(crystal.height, 40, "锁存展开")
        wait(600)
        compare(crystal.height, 30, "窗口落后回常态")
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
        // second 独立步进（相对自身值）
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
        // first = (90-100)/(0-100) = 0.1、second = 0.9
        compare(s.surface.x, 0.1 * 200)
        compare(s.surface.x + s.surface.width, 0.9 * 200)
        compare(s.surface.width, 0.8 * 200)
    }

    function test_surfaceReplacement() {
        // surface 替换最低要求：任意简单 Item（Rectangle 自行 fill）替换 →
        // 填充区间盒（几何由 Binding 组施加——替换实例同样受控）
        const s = createTemporaryObject(sliderWithRectSurface, root, {})
        const rect = s.surface
        verify(rect !== null, "替换 surface 存在")
        verify(rect.objectName === "customSurface", "surface 已被替换")
        s.setValues(0.25, 0.75)
        compare(s.surface.x, 50)
        compare(s.surface.width, 100)
        compare(rect.width, 100)
        compare(rect.height, 40)
        // 值变化跟随
        s.setValues(0.4, 0.6)
        compare(s.surface.x, 80)
        compare(s.surface.width, 40)
        compare(rect.width, 40)
    }

    function test_handlePluggable() {
        // handle 插拔：替换 first.handle（模板 handle 插拔契约）——替换
        // 实例生效、second 默认不受影响
        const s = createTemporaryObject(sliderWithCustomHandle, root, {})
        verify(s.first.handle.objectName === "customHandle", "first handle 已替换")
        verify(s.second.handle !== null, "second handle 存在")
    }
}
