import QtQuick
import QtTest
import Qool
import Qool.Controls

// Dial 测试（Qool.Controls/Dial.qml——T.Dial 模板 + ColorMapper 三色采样
// handle 按压色）
//
// 被测契约（外部行为与公开契约——不测内部实现）：
// - 默认三色：highColor/midColor/lowColor = Style.red/yellow/green
// - valueColor 采样：position 0 → lowColor、0.5 → midColor、1 → highColor
//   （采样随 position 实时变化）
// - 源色变化跟随：改 high/mid/low 色 → valueColor 立即重采样——即使
//   position 不变。回归缺陷：colorAt 为 C++ 方法、QML 绑定不追踪方法体
//   内 stops 访问——直接绑定会冻结初始采样、源色变化不触发重算
//
// 注：valueColor 经 Binding 流入 handle 按压色（pressed 时 handle.color =
// valueColor）；按压触发为模板交互，offscreen 无法注入合成事件（同 Slider
// 探针实测），故 valueColor 采样经 dial.data 定位 colorMapper（objectName）
// 断言。
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例。

TestCase {
    id: root

    name: "Dial"
    width: 200
    height: 200

    Component {
        id: dialComp
        Dial {
            width: 100
            height: 100
        }
    }

    function makeDial(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(dialComp, root, props)
    }

    // —— 采样映射器定位（non-Item 子对象——不在 children，经 data 数组找
    // objectName 标记）——
    function colorMapper(d) {
        for (let i = 0; i < d.data.length; ++i)
            if (d.data[i].objectName === "colorMapper")
                return d.data[i]
        return null
    }

    function test_defaults() {
        const d = makeDial({})
        compare(d.highColor, d.Style.red)
        compare(d.midColor, d.Style.yellow)
        compare(d.lowColor, d.Style.green)
        const m = colorMapper(d)
        verify(m !== null, "colorMapper 存在")
        // 初始（completed 后）采样 = position 0 → lowColor（通道比较——QColor
        // 整值 compare 因内部表示差异不可靠，同 Slider 测试）
        compare(m.valueColor.r, d.lowColor.r, "初始采样 = lowColor r")
        compare(m.valueColor.g, d.lowColor.g, "初始采样 = lowColor g")
        compare(m.valueColor.b, d.lowColor.b, "初始采样 = lowColor b")
    }

    function test_valueColorPosition() {
        // 采样随 position：0 → lowColor、0.5 → midColor、1 → highColor
        // （Qt 信号同步——设 value 后 positionChanged 同步触发重采样）
        const d = makeDial({})
        const m = colorMapper(d)
        d.value = 0.5
        compare(m.valueColor.r, d.midColor.r, "position 0.5 采样 = midColor r")
        compare(m.valueColor.g, d.midColor.g, "position 0.5 采样 = midColor g")
        compare(m.valueColor.b, d.midColor.b, "position 0.5 采样 = midColor b")
        d.value = 1
        compare(m.valueColor.r, d.highColor.r, "position 1 采样 = highColor r")
        compare(m.valueColor.g, d.highColor.g, "position 1 采样 = highColor g")
        compare(m.valueColor.b, d.highColor.b, "position 1 采样 = highColor b")
        d.value = 0
        compare(m.valueColor.r, d.lowColor.r, "position 回 0 采样回到 lowColor")
    }

    function test_valueColorFollowsSource() {
        // 源色变化须立即反映到采样——即使 position 不变。colorAt 为 C++
        // 方法、QML 绑定不追踪方法体内对 stops 的访问——valueColor 经
        // Connections 手动驱动（completed 初始采样 + 信号重采样）；若直接
        // 绑定，源色变化不触发重算（真实缺陷回归防护）。
        const d = makeDial({})
        const m = colorMapper(d)
        d.lowColor = "#f8f8f8"
        compare(m.valueColor.r, d.lowColor.r, "lowColor 变化 → 采样 r 立即跟随（position 未动）")
        compare(m.valueColor.g, d.lowColor.g)
        compare(m.valueColor.b, d.lowColor.b)
        d.highColor = "#ff8800"
        compare(m.valueColor.r, d.lowColor.r, "position 0 时 highColor 变化不影响 from 端采样")
        compare(m.valueColor.g, d.lowColor.g)
        compare(m.valueColor.b, d.lowColor.b)
        d.value = 1
        compare(m.valueColor.r, d.highColor.r, "position 1 后采样离开 from 端")
        compare(m.valueColor.g, d.highColor.g)
        compare(m.valueColor.b, d.highColor.b)
    }
}
