import QtQuick
import QtTest
import Qool
import Qool.Controls

// Slider 测试（Qool.Controls/Slider.qml——T.Slider 模板 + Crystal 渐变轨道
// + 菱形手柄；交互为模板默认，本批次不测鼠标路径）
//
// 被测契约（外部行为与公开契约——不测内部实现）：
// - 默认状态自洽（implicit 80×25、color = Style.accent、
//   backgroundColor = Style.buttonText、borderColor = 自动对比推荐、
//   justMoved 初始 false）
// - 轨道几何：background 为 Item 容器（尺寸由外部 Binding 控 = root −
//   insets，与 Control 自动布局一致），内部 Crystal 常态收缩 = root.height −
//   bound(3, h×25%, 25) + 完全居中（水平铺满容器宽、垂直居中）——替换
//   background 后新实例尺寸同样受控（插拔安全）；轨道静态——值写入不改变
//   轨道几何
// - 渐变契约：左端 = backgroundColor 75% 透明、右端 = color，锚定切角内侧
//   （x = [h/2, w−h/2]——直边区行程）；兜底色 = color（渐进降级）
// - 手柄：菱形（width = height）、常态 = root.height − 收缩偏移（与轨道
//   同高贴斜边）、写入值 → 展开占满控件高（justMoved 锁存 500ms）、窗口落
//   回常态；展开不超出控件边界
// - 采样色不透明化：手柄常态色 = 渐变在值位置的采样色但不透明（position
//   0 → backgroundColor 不透明版，非 0.75 透明轨道端）
// - justMoved 锁存窗口（500ms 滑动——写入即触发、独立回落）
// - insets 响应：background 尺寸 = root 尺寸 − insets
//
// 注：真实鼠标交互（模板拖动、hover、pressed 反馈）不在自动化范围——
// offscreen 不注入合成事件；展开反馈经 justMoved（值写入）路径断言。
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例；
// 动画统一关闭（animationEnabled: false）——展开断言即时。
//
// 测试基准：200×40 → 收缩偏移 = bound(3, 10, 25) = 10；轨道 200×30 居中
// y=5；手柄常态高 30、展开 40。渐变切角锚定：x1 = 15、x2 = 185（h=30）。

TestCase {
    id: root

    name: "Slider"
    width: 400
    height: 300

    Component {
        id: sliderComp
        Slider {
            width: 200
            height: 40
            animationEnabled: false
        }
    }

    // background 替换组件（插拔最低要求——任意 Item 替换后尺寸仍受控）
    Component {
        id: sliderWithRectBg
        Slider {
            width: 200
            height: 40
            animationEnabled: false
            background: Rectangle {
                objectName: "customBg"
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

    // 手柄内部 Crystal（handleRoot.children 仅含可视子项：
    // [0]=Crystal——ColorMapper 为非 Item 对象不在 children 内）
    function handleCrystal(s) {
        return s.handle.children[0]
    }

    function test_defaults() {
        const s = makeSlider({})
        compare(s.implicitWidth, 80)
        compare(s.implicitHeight, 25)
        compare(s.color, s.Style.accent)
        compare(s.backgroundColor, s.Style.buttonText)
        compare(s.borderColor, ThemeHQ.recommendForeground(s.backgroundColor))
        compare(s.justMoved, false)
        verify(s.valueVelocity !== undefined, "valueVelocity 存在")
        // 轨道 = background 本身（默认 Crystal）
        verify(s.background !== null, "background 存在")
    }

    function test_trackGeometry() {
        // 轨道：容器尺寸 = root − insets（外部 Binding），内部 Crystal 常态
        // 收缩 + 居中——静态（不随值变）
        const s = makeSlider({})
        const track = findChild(s.background, "track")
        verify(track !== null, "轨道存在")
        compare(s.background.width, 200, "容器宽 = root 宽（无 insets）")
        compare(s.background.height, 40, "容器高 = root 高")
        compare(track.width, 200, "轨道宽 = 容器宽（尖点贴边不外溢）")
        compare(track.height, 40 - 10, "轨道常态收缩 = root 高 − 偏移")
        compare(track.x, 0, "轨道水平铺满容器宽（完全居中——不外溢）")
        compare(track.y, (40 - 30) / 2, "轨道垂直居中")
        compare(track.borderColor, s.borderColor, "轨道描边消费 borderColor")
        // 轨道静态——值写入（justMoved）不改变轨道几何
        s.value = 0.5
        compare(track.width, 200)
        compare(track.height, 30)
        compare(track.y, 5)
    }

    function test_trackGradient() {
        // 渐变：左端 = backgroundColor 75% 透明、右端 = color；
        // 锚定切角内侧（直边区行程 [h/2, w−h/2]）
        const s = makeSlider({})
        const t = findChild(s.background, "track")
        const g = t.fillGradient
        verify(g !== undefined, "fillGradient 存在")
        compare(g.stops.length, 2)
        compare(g.stops[0].color, Qt.alpha(s.backgroundColor, 0.75), "渐变左端 = bg 75% 透明")
        compare(g.stops[1].color, s.color, "渐变右端 = color")
        compare(g.x1, 30 / 2, "锚定切角内侧左端")
        compare(g.x2, 200 - 30 / 2, "锚定切角内侧右端")
        compare(g.y1, 30 / 2)
        compare(g.y2, 30 / 2)
        // 兜底色 = color（渐变失效时渐进降级）
        compare(t.color, s.color)
    }

    function test_handleRestAndExpand() {
        // 菱形（width = height）；常态收缩 = root 高 − 偏移；写入 → 展开
        // 占满控件高；窗口落回常态（动画关闭——即时）
        const s = makeSlider({})
        const c = handleCrystal(s)
        compare(c.width, 30, "菱形常态")
        compare(c.height, 30, "常态收缩 = root 高 − 偏移")
        s.value = 0.5
        compare(c.height, 40, "锁存展开占满控件高")
        compare(c.width, 40, "展开仍为菱形")
        wait(600)
        compare(c.height, 30, "窗口落后回常态")
        compare(c.width, 30)
    }

    function test_handleSampleColor() {
        // 手柄常态色 = 渐变在值位置的采样色但不透明化：position 0 → 不透明
        // backgroundColor（轨道端是 0.75 透明版——手柄为实体）
        const s = makeSlider({})
        const c = handleCrystal(s)
        s.value = 0
        verify(c.color.a === 1, "手柄采样不透明化（a=1）")
        compare(c.color.r, s.backgroundColor.r, "position 0 采样 = bg 的 r 通道")
        compare(c.color.g, s.backgroundColor.g, "position 0 采样 = bg 的 g 通道")
        compare(c.color.b, s.backgroundColor.b, "position 0 采样 = bg 的 b 通道")
        verify(c.color.a !== Qt.alpha(s.backgroundColor, 0.75).a, "手柄非轨道 0.75 透明版")
        s.value = 1
        compare(c.color.r, s.color.r, "position 1 采样 = color 的 r 通道")
        compare(c.color.g, s.color.g, "position 1 采样 = color 的 g 通道")
        compare(c.color.b, s.color.b, "position 1 采样 = color 的 b 通道")
        verify(c.color.a === 1, "position 1 仍不透明")
    }

    function test_justMovedLatch() {
        // 锁存窗口：写入即触发、500ms 回落
        const s = makeSlider({})
        compare(s.justMoved, false)
        s.value = 0.5
        verify(s.justMoved, "值写入锁存")
        wait(600)
        verify(!s.justMoved, "窗口落")
    }

    function test_backgroundPluggable() {
        // 替换 background：新实例尺寸仍受外部 Binding 控（root − insets）——
        // 插拔安全；收缩/外观由替换者自负（容器尺寸 = root − insets）
        const s = createTemporaryObject(sliderWithRectBg, root, {})
        const bg = s.background
        verify(bg.objectName === "customBg", "background 已被替换")
        compare(bg.width, 200, "替换后宽仍受控")
        compare(bg.height, 40, "替换后高仍受控（root − insets）")
    }

    function test_insets() {
        // background 容器响应 insets（width = root − left − right、
        // height = root − top − bottom）；内部轨道在容器内收缩 + 居中
        const s = makeSlider({})
        const track = findChild(s.background, "track")
        s.leftInset = 10
        s.topInset = 4
        compare(s.background.width, 190, "leftInset 收缩容器宽")
        compare(s.background.height, 36, "topInset 收缩容器高")
        compare(track.width, 190, "轨道宽随容器")
        compare(track.height, 36 - 10, "轨道在容器内收缩")
        compare(track.y, (36 - 26) / 2, "轨道容器内居中")
    }
}
