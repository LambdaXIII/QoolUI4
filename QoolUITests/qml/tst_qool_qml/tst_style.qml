import QtQuick
import QtTest
import Qool

// Style 附加属性行为契约测试（docs/articles/style-system.md「行为契约」）
//
// 被测契约：
// - C1 传播构造：theme 注入沿附加树生效——子节点读到的主题名与数据与根一致
// - C4 相等赋值不刷新：赋相同值不产生任何属性信号（set_value 相等守卫
//   比较该键当前值，短路）
// - C5 覆盖不传播：typed 覆盖只影响本节点（单实例粒度），子孙读 theme 默认
// - C6 组切换：宿主禁用时属性读 Disabled 组（组面写入制造确定性差异；
//   窗口失活不可模拟——offscreen 无窗口，Inactive 组由 C9 数据层覆盖）
// - C7 附加树连通：未声明 Style 的中间节点透明跳过，传播不断
// - C12 组面读写：StyleGroupAgent 读指定组、写单组不影响其他组
//
// 隔离策略：每个测试函数 createTemporaryQmlObject 独立实例；绑定/传播
// 异步，断言用 tryCompare/tryVerify 轮询。颜色断言用 toString() 规范化
//（QML color 值类型无 .name 属性——QColor 的 C++ 属性未暴露；.name 恒
// undefined，compare(undefined, undefined) 假 PASS）。QML 测试批次无主题
// 插件（仅 system）——本批次首个实例化 Style 的测试触发 ThemeDB 首次
// 初始化 "No ThemeLoader installed" WARN 为预期（tst_basiclabel 同款）。

TestCase {
    id: root

    name: "Style"
    width: 320
    height: 320

    function makeSpy(target, signalName) {
        const spy = Qt.createQmlObject("import QtTest; SignalSpy {}", root)
        spy.target = target
        spy.signalName = signalName
        return spy
    }

    // C1：theme 注入沿附加树生效
    function test_themeInjection() {
        const scene = createTemporaryQmlObject("
            import QtQuick
            import Qool
            Item {
                objectName: 'scene'
                Style.theme: 'system'
                Item {
                    objectName: 'child'
                    property string probeTheme: Style.theme
                    property color probeAccent: Style.accent
                }
            }", root)
        const child = scene.children[0]
        tryCompare(child, "probeTheme", "system", 1000)
        tryVerify(function() {
            return child.probeAccent.toString() === scene.Style.accent.toString()
        }, 1000, "child data equals root data")
    }

    // C4：相等赋值不刷新（当前实现守卫笔误 → 期望 FAIL 暴露）
    function test_equalAssignNoRefresh() {
        const s = createTemporaryQmlObject("
            import QtQuick
            import Qool
            Item {
                objectName: 's'
                property color probe: Style.accent
                Style.accent: '#ff8800'
            }", root)
        tryVerify(function() { return s.probe.toString() === '#ff8800' },
            1000)
        const spy = makeSpy(s.Style, "accentChanged")
        const cur = s.probe
        s.Style.accent = cur
        compare(spy.count, 0, "equal assignment emits nothing")
    }

    // C5：typed 覆盖只影响本节点，不向子孙传播
    function test_overrideNotPropagated() {
        const scene = createTemporaryQmlObject("
            import QtQuick
            import Qool
            Item {
                objectName: 'scene'
                Style.theme: 'system'
                Item {
                    objectName: 'node'
                    property color probeAccent: Style.accent
                    Style.accent: '#ff8800'
                }
                Item {
                    objectName: 'leaf'
                    property color probeAccent: Style.accent
                }
            }", root)
        const node = scene.children[0]
        const leaf = scene.children[1]
        tryVerify(function() { return node.probeAccent.toString() === '#ff8800' },
            1000)
        // 叶子未覆盖 → theme 默认（= 根值），非节点的覆盖值
        tryVerify(function() {
            return leaf.probeAccent.toString() === scene.Style.accent.toString()
        }, 1000, "leaf reads theme default")
        verify(leaf.probeAccent.toString() !== '#ff8800',
            "override does not propagate to descendants")
    }

    // C6：组切换——禁用时属性读 Disabled 组（组面写入制造确定性差异）
    function test_groupSwitch() {
        const s = createTemporaryQmlObject("
            import QtQuick
            import Qool
            Item {
                objectName: 's'
                property color probeAccent: Style.accent
                Style.active.accent: '#ff0000'
                Style.inactive.accent: '#00ff00'
                Style.disabled.accent: '#0000ff'
            }", root)
        tryVerify(function() { return s.probeAccent.toString() === '#ff0000' },
            1000, "active group")
        s.enabled = false
        tryVerify(function() { return s.probeAccent.toString() === '#0000ff' },
            1000, "disabled group")
        s.enabled = true
        tryVerify(function() { return s.probeAccent.toString() === '#ff0000' },
            1000, "back to active")
    }

    // C7：未声明 Style 的中间节点透明跳过，传播不断
    function test_untypedNodePassthrough() {
        const scene = createTemporaryQmlObject("
            import QtQuick
            import Qool
            Item {
                objectName: 'scene'
                Style.theme: 'system'
                Item {
                    objectName: 'mid'
                    Item {
                        objectName: 'leaf'
                        property string probeTheme: Style.theme
                        property color probeAccent: Style.accent
                    }
                }
            }", root)
        const mid = scene.children[0]
        const leaf = mid.children[0]
        tryCompare(leaf, "probeTheme", "system", 1000)
        tryVerify(function() {
            return leaf.probeAccent.toString() === scene.Style.accent.toString()
        }, 1000, "propagation passes untyped node")
    }

    // C12：组面读写——读指定组、写单组不影响其他组
    function test_groupFaceReadWrite() {
        const s = createTemporaryQmlObject("
            import QtQuick
            import Qool
            Item {
                objectName: 's'
                property color activeProbe: Style.active.accent
                property color inactiveProbe: Style.inactive.accent
                property color disabledProbe: Style.disabled.accent
                Style.active.accent: '#ff0000'
                Style.inactive.accent: '#00ff00'
                Style.disabled.accent: '#0000ff'
            }", root)
        tryVerify(function() { return s.activeProbe.toString() === '#ff0000' },
            1000)
        tryVerify(function() { return s.inactiveProbe.toString() === '#00ff00' },
            1000)
        tryVerify(function() { return s.disabledProbe.toString() === '#0000ff' },
            1000)
        // 写单组只影响该组
        s.Style.inactive.accent = '#00aa00'
        tryVerify(function() { return s.inactiveProbe.toString() === '#00aa00' },
            1000)
        compare(s.Style.active.accent.toString(), '#ff0000',
            "active group unaffected")
        compare(s.Style.disabled.accent.toString(), '#0000ff',
            "disabled group unaffected")
    }
}
