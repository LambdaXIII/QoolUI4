import QtQuick
import QtTest
import Qool
import Qool.Color
import Qool.Controls

// ChannelControl 测试（Qool.Color/ChannelControl.qml——单通道
// 组合件：外壳集束 + 自持 value 链 + orientation 双布局）。
//
// 被测契约（公开契约——docs/reference/Qool.Color/ChannelControl.md 为准绳）：
// - 集束链：外壳 value 写入 → assistant 通道变化；assistant 变化 → value 跟随
// - orientation：默认水平（编辑行上 + 滑块下，两行等宽）；Qt.Vertical 切竖直
//   （竖直滑块上 + 竖直镜像编辑行下——编辑行内部数字框在上/短标签在下）
// - readOnly 转发 → 编辑行 readOnly
//
// 隔离：每个测试函数独立实例；动画统一关闭。
// 内部定位：edit/slider 经 objectName + findChild（递归搜索——不依赖
// children 序或内部实现）；编辑行内部 tag/editor 同法。

TestCase {
    id: root

    name: "ChannelControl"
    width: 300
    height: 300

    Component {
        id: ctrlComp

        ChannelControl {
            Style.animationEnabled: false
        }
    }

    function createControl(props) {
        return createTemporaryObject(ctrlComp, root, props || {})
    }

    function findItem(item, name) {
        if (item.objectName === name)
            return item
        for (let i = 0; i < item.children.length; ++i) {
            const r = findItem(item.children[i], name)
            if (r)
                return r
        }
        return null
    }

    function fuzzy(a, b) {
        return Math.abs(a - b) < 0.01
    }

    function yIn(item, space) {
        return item.mapToItem(space, 0, 0).y
    }

    // -- 默认水平布局：编辑行上 + 滑块下，两行等宽 --
    function test_orientationDefault() {
        const c = createControl()
        compare(c.orientation, Qt.Horizontal, "default orientation")
        verify(c.horizontal && !c.vertical, "derived flags")
        const edit = findItem(c.contentItem, "edit")
        const slider = findItem(c.contentItem, "hslider")
        verify(edit && slider, "horizontal children exist")
        // hslider 在 Loader 内——y 相对其父 Loader 而非 contentItem，
        // 断言前统一映射到 contentItem 坐标系
        verify(yIn(edit, c.contentItem) < yIn(slider, c.contentItem),
               "edit above slider")
        verify(fuzzy(edit.width, c.contentItem.width)
               && fuzzy(slider.width, c.contentItem.width),
               "rows equal width")
    }

    // -- 竖直布局：竖直滑块上 + 竖直镜像编辑行下 --
    function test_orientationVertical() {
        const c = createControl({ orientation: Qt.Vertical })
        verify(c.vertical && !c.horizontal, "derived flags")
        const slider = findItem(c.contentItem, "vslider")
        const edit = findItem(c.contentItem, "edit")
        verify(slider && edit, "vertical children exist")
        verify(yIn(slider, c.contentItem) < yIn(edit, c.contentItem),
               "slider above edit")
        verify(fuzzy(slider.width, c.contentItem.width),
               "slider fills width")
        // 编辑行内部：竖直翻转（tagOnTop）——数字框在上（贴滑块侧）、
        // 短标签在下；行序由显式属性驱动，不借环境镜像
        const editor = findItem(edit.contentItem, "editor")
        const tag = findItem(edit.contentItem, "tag")
        verify(editor && tag, "edit internals found")
        verify(edit.tagOnTop, "edit vertical flip driven by control layout")
        verify(editor.y < tag.y, "flipped vertical edit: editor above tag")
    }

    // -- 切换往返：布局随 orientation 重建，链经共享 assistant 保持收敛 --
    function test_orientationSwitchChain() {
        const c = createControl()
        const ca = c.colorAssistant
        // 默认 channel = HSLHue → 链走 hslHueF（channelNameF 分派）。
        c.value = 0.4
        verify(fuzzy(ca.hslHueF, 0.4), "write chain (horizontal)")
        c.orientation = Qt.Vertical
        const slider = findItem(c.contentItem, "vslider")
        verify(slider, "vertical layout after switch")
        verify(fuzzy(slider.value, 0.4), "slider follows shared channel")
        ca.hslHueF = 0.7
        verify(fuzzy(c.value, 0.7), "read chain survives switch")
    }

    // -- readOnly 转发 --
    function test_readOnlyForward() {
        const c = createControl({ readOnly: true })
        const edit = findItem(c.contentItem, "edit")
        verify(edit.readOnly, "readOnly forwarded to edit")
    }
}
