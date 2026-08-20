import QtQuick
import QtTest
import Qool
import Qool.Controls

// Slider 测试（Qool.Controls/Slider.qml——T.Slider 模板 + Crystal 渐变轨道
// + 菱形手柄；交互为模板默认，本批次不测鼠标路径）
//
// 被测契约（外部行为与公开契约——不测内部实现）：
// - 默认状态自洽（implicit 150×25、无实例色属性——配色经 Style 语义槽
//   消费：轨道兜底 = Style.accent、描边 = recommendForeground(buttonText)）
// - 轨道几何：background 为 Item 容器（尺寸经 Control 标准自动布局 =
//   root − insets），内部 Crystal 常态收缩 = root.height −
//   bound(3, h×25%, 25) + 完全居中（水平铺满容器宽、垂直居中）——替换
//   background 后新实例尺寸同样受控（插拔安全）；轨道静态——值写入不改变
//   轨道几何
// - 渐变契约：左端 = backgroundColor 75% 透明、右端 = color，锚定切角内侧
//   （x = [h/2, w−h/2]——直边区行程）；兜底色 = color（渐进降级）
// - 手柄：菱形（width = height）、常态 = 可用高 − 收缩偏移（与轨道
//   同高贴斜边）、写入值 → 展开占满控件高（TimerLatch 锁存 500ms）、窗口
//   落回常态；展开不超出控件边界
// - 采样色不透明化：手柄常态色 = 渐变在值位置的采样色但不透明（position
//   0 → backgroundColor 不透明版，非 0.75 透明轨道端）
// - 锁存窗口（500ms 滑动——写入即触发、独立回落）——经手柄展开路径断言
//   （锁存内化于 handle，无独立接口）
// - insets 响应：background 尺寸 = root 尺寸 − insets
//
// 注：真实鼠标交互（模板拖动、hover、pressed 反馈）不在自动化范围——
// offscreen 不注入合成事件；展开反馈经值写入（锁存）路径断言。
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
        compare(s.implicitWidth, 150)
        compare(s.implicitHeight, 25)
        // 接口收敛：控件不再暴露实例色属性——配色经 Style 语义槽消费
        // （统一样式接口，宿主经 Style 附着传播换色）
        verify(s.color === undefined, "Slider 无 color 属性")
        verify(s.backgroundColor === undefined, "无 backgroundColor 属性")
        verify(s.borderColor === undefined, "无 borderColor 属性")
        // 默认视觉消费 Style：轨道兜底 = Style.accent、描边 =
        // recommendForeground(Style.buttonText)
        verify(s.background !== null, "background 存在")
        const track = findChild(s.background, "track")
        verify(track !== null, "轨道存在")
        compare(track.color, s.Style.accent, "轨道兜底色 = Style.accent")
        compare(track.borderColor, ThemeHQ.recommendForeground(s.Style.buttonText),
                "轨道描边 = recommend(buttonText)")
    }

    function test_trackGeometry() {
        // 轨道：容器尺寸 = root − insets（标准自动布局），内部 Crystal 常态
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
        compare(track.borderColor, ThemeHQ.recommendForeground(s.Style.buttonText),
                "轨道描边 = recommend(buttonText)")
        // 轨道静态——值写入不改变轨道几何
        s.value = 0.5
        compare(track.width, 200)
        compare(track.height, 30)
        compare(track.y, 5)
    }

    function test_trackGradient() {
        // 渐变：左端 = Style.buttonText 75% 透明、右端 = Style.accent；
        // 锚定切角内侧（直边区行程 [h/2, w−h/2]）
        const s = makeSlider({})
        const t = findChild(s.background, "track")
        const g = t.fillGradient
        verify(g !== undefined, "fillGradient 存在")
        compare(g.stops.length, 2)
        compare(g.stops[0].color, Qt.alpha(s.Style.buttonText, 0.75), "渐变左端 = buttonText 75% 透明")
        compare(g.stops[1].color, s.Style.accent, "渐变右端 = accent")
        compare(g.x1, 30 / 2, "锚定切角内侧左端")
        compare(g.x2, 200 - 30 / 2, "锚定切角内侧右端")
        compare(g.y1, 30 / 2)
        compare(g.y2, 30 / 2)
        // 兜底色 = Style.accent（渐变失效时渐进降级）
        compare(t.color, s.Style.accent)
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
        // Style.buttonText（轨道端是 0.75 透明版——手柄为实体）
        const s = makeSlider({})
        const c = handleCrystal(s)
        s.value = 0
        verify(c.color.a === 1, "手柄采样不透明化（a=1）")
        compare(c.color.r, s.Style.buttonText.r, "position 0 采样 = buttonText 的 r 通道")
        compare(c.color.g, s.Style.buttonText.g, "position 0 采样 = buttonText 的 g 通道")
        compare(c.color.b, s.Style.buttonText.b, "position 0 采样 = buttonText 的 b 通道")
        verify(c.color.a !== Qt.alpha(s.Style.buttonText, 0.75).a, "手柄非轨道 0.75 透明版")
        s.value = 1
        compare(c.color.r, s.Style.accent.r, "position 1 采样 = accent 的 r 通道")
        compare(c.color.g, s.Style.accent.g, "position 1 采样 = accent 的 g 通道")
        compare(c.color.b, s.Style.accent.b, "position 1 采样 = accent 的 b 通道")
        verify(c.color.a === 1, "position 1 仍不透明")
    }

    function test_handleSampleColorFollowsSource() {
        // 源色（Style.buttonText/accent）传播变化须立即反映到手柄采样——
        // 即使 position 不变。colorAt 为 C++ 方法、QML 绑定不追踪方法体内
        // 对 stops 的访问——手柄颜色经手动驱动（completed 初始采样 +
        // position 变化重采样 + crystal 内哨兵只读属性捕获 Style 传播变化）；
        // 若直接绑定，初始会冻结在未就绪 stops 的默认黑（真实缺陷：默认
        // value:0 + 主题加载场景），本用例回归防护。换色经宿主在实例挂
        // Style 附着属性（s.Style.buttonText = …——附着传播，粒度单实例）。
        // 通道比较（QColor 整值 compare 因内部表示差异不可靠——同款）
        const s = makeSlider({})
        const c = handleCrystal(s)
        compare(c.color.r, s.Style.buttonText.r, "初始（completed 后）采样 = from 端 r")
        compare(c.color.g, s.Style.buttonText.g, "初始采样 = from 端 g")
        compare(c.color.b, s.Style.buttonText.b, "初始采样 = from 端 b")
        s.Style.buttonText = "#f8f8f8"
        // Style 附着传播 + 哨兵绑定重算在事件循环内完成——轮询等待手柄
        // 跟随（非同步；视觉上 UI 帧内更新即可）
        for (let i = 0; i < 100 && c.color.r !== s.Style.buttonText.r; ++i)
            wait(10)
        compare(c.color.r, s.Style.buttonText.r, "buttonText 传播变化 → 手柄 r 跟随")
        compare(c.color.g, s.Style.buttonText.g)
        compare(c.color.b, s.Style.buttonText.b)
        s.Style.accent = "#ff8800"
        for (let i = 0; i < 100 && c.color.r !== s.Style.buttonText.r; ++i)
            wait(10)
        compare(c.color.r, s.Style.buttonText.r, "value:0 时 accent 变化不影响 from 端采样")
        compare(c.color.g, s.Style.buttonText.g)
        compare(c.color.b, s.Style.buttonText.b)
        s.value = 0.5
        verify(c.color.r !== s.Style.buttonText.r || c.color.g !== s.Style.buttonText.g,
               "position 变化后采样离开 from 端")
        verify(c.color.g < s.Style.buttonText.g, "position 0.5 采样向 to 端（accent 的 g 更低）偏移")
    }

    function test_backgroundPluggable() {
        // 替换 background：新实例尺寸仍受标准自动布局控（root − insets）——
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

    // —— orientation × RTL 契约（ADR-0010）——
    // 正交统一：orientation 承载轴向（horizontal）、RTL 镜像仅水平生效；
    // side = 法向尺寸（水平 = availableHeight、垂直 = availableWidth）横竖
    // 对称、镜像无关。渐变锚定值增大端（水平 RTL 坐标对调、stop 色序不变；
    // 垂直恒 from 底 → to 顶——Qt 垂直惯例 visualPosition 恒 1−position，
    // 不受 RTL 影响）；采样用 position（不镜像）——与渐变几何一致（定位
    // visualPosition 镜像、采样 position 不镜像，互补）。
    // 隔离：每用例独立实例；RTL 经 s.LayoutMirroring.enabled + tryCompare
    // mirrored（轮询——禁止固定 sleep）。

    function test_verticalGeometry() {
        // 垂直：handle 边长 = 法向（availableWidth）、x 居中、y 由
        // visualPosition；轨道沿法向收缩 + 居中；渐变沿 y 轴锚定；
        // implicit 随 orientation 交换
        const s = makeSlider({ orientation: Qt.Vertical, width: 40, height: 200 })
        const track = findChild(s.background, "track")
        // side = availableWidth = 40 → shrinkSize = bound(3, 10, 25) = 10
        compare(s.handle.width, 40, "handle 边长 = 法向（availableWidth）")
        compare(s.handle.height, 40, "handle 恒为菱形")
        compare(s.handle.x, 0, "垂直 handle x 居中")
        // Qt 垂直惯例：visualPosition 恒 = 1−position（与 RTL 无关）——值 0 →
        // visualPosition 1 → handle 底部、值 1 → 顶部
        compare(s.handle.y, 200 - 40, "值 0 → visualPosition 1 → y 底部")
        s.value = 1
        compare(s.handle.y, 0, "值 1 → visualPosition 0 → y 顶部")
        compare(s.handle.x, 0, "垂直 x 不随值变")
        // 轨道：height 铺满、width 沿法向收缩 + x 居中
        compare(track.width, 40 - 10, "轨道沿法向收缩（width = 容器宽 − shrinkSize）")
        compare(track.x, 5, "轨道法向居中（x = halfShrinkSpace）")
        compare(track.height, 200, "轨道沿主轴铺满")
        compare(track.y, 0, "轨道主轴不偏移")
        // 渐变：垂直锚定——cut = min(30,200)/2 = 15
        const g = track.fillGradient
        compare(g.x1, 15, "垂直渐变 x 居中")
        compare(g.x2, 15)
        compare(g.y1, 200 - 15, "垂直渐变 from 端 = 底（值小端，Qt 垂直惯例）")
        compare(g.y2, 15, "垂直渐变 to 端 = 顶（值增大端 accent）")
        // implicit 随 orientation 交换
        compare(s.implicitWidth, 25, "垂直 implicit 交换（窄）")
        compare(s.implicitHeight, 150, "垂直 implicit 交换（长）")
    }

    function test_rtlMapping() {
        // 水平 + RTL：handle 值增大靠左（visualPosition 反转）、渐变端点
        // 对调；采样用 position（不镜像）——与对调渐变几何一致
        const s = makeSlider({})
        s.LayoutMirroring.enabled = true
        tryCompare(s, "mirrored", true)
        const track = findChild(s.background, "track")
        s.value = 0.75
        compare(s.visualPosition, 1 - 0.75, "RTL visualPosition 反转")
        // handle 边长 = side = availableHeight = 40
        compare(s.handle.width, 40)
        // x = leftPadding + visualPosition*(availableWidth − width)
        // RTL value=0.75 → visualPosition 0.25 → x = 0.25*(200−40) = 40
        compare(s.handle.x, 0.25 * (200 - 40), "RTL 值增大 → handle 靠左")
        compare(s.handle.y, 0, "水平 RTL y 仍居中")
        // 渐变端点对调：水平 RTL x1 = w−cut、x2 = cut（cut = min(200,30)/2 = 15）
        const g = track.fillGradient
        compare(g.x1, 200 - 15, "RTL 渐变 from 端移到右（对调）")
        compare(g.x2, 15, "RTL 渐变 to 端移到左（accent 随值增大端）")
        compare(g.y1, 15, "RTL 水平渐变 y 仍居中")
        compare(g.y2, 15)
        // 采样不镜像：position 0.75 → 与 LTR 同 value 采样色一致
        const ltr = makeSlider({})
        ltr.value = 0.75
        compare(handleCrystal(s).color, handleCrystal(ltr).color, "采样用 position（不镜像）——与 LTR 同值一致")
    }

    function test_verticalRtlCombined() {
        // 垂直 + RTL：Qt 垂直视觉不受 RTL 影响（visualPosition 恒反转、值大
        // 恒在顶）——与垂直 LTR 完全一致，验证两维度不冲突（RTL 仅水平生效）
        const s = makeSlider({ orientation: Qt.Vertical, width: 40, height: 200 })
        s.LayoutMirroring.enabled = true
        tryCompare(s, "mirrored", true)
        const track = findChild(s.background, "track")
        s.value = 0.75
        compare(s.mirrored, true, "垂直 RTL 环境成立")
        compare(s.visualPosition, 1 - 0.75, "垂直 visualPosition 恒反转（与 RTL 无关，跟随 Qt 模板）")
        compare(s.handle.x, 0, "垂直 x 居中（不受 RTL）")
        compare(s.handle.y, 0.25 * (200 - 40), "值大 → handle 靠上（与垂直 LTR 一致）")
        // 渐变垂直不受 RTL：from 恒底、to 恒顶（不对调——与垂直 LTR 相同）
        const g = track.fillGradient
        compare(g.y1, 200 - 15, "垂直渐变 from 恒底（不受 RTL）")
        compare(g.y2, 15, "垂直渐变 to 恒顶（accent 随值增大端，不受 RTL）")
        compare(g.x1, 15, "垂直渐变 x 居中")
        compare(g.x2, 15)
    }
}
