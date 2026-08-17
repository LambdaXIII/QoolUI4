import QtQuick
import QtTest
import Qool
import Qool.Controls.Components

// QoolBGBox space 语义测试（Qool.Controls.Components/QoolBGBox.qml）
//
// 被测契约：
// - *Space 有/无 label 两形态：label 可见时 topSpace = 标签高 + 边框宽、
//   left/rightSpace 收紧为边框宽、bottomSpace = control.bottomSpace + 边框宽；
//   无可见 label 时 top/bottomSpace 仅为边框宽、
//   left/rightSpace = control.*Space + 边框宽
// - label 空安全：label 未设置（默认标签空文本）/ 空文本 / 显式置 null
//   一律按无标签处理（label?.visible 空安全短路）
// - 覆盖语义：QoolBGBox 覆盖 QoolBox 同名 *Space（同系同类语义）——
//   label 可见时 left/rightSpace 收紧为边框宽，与 QoolBox 转发 control 的值不同
// - settings 显式特化：默认 settings 的 borderWidth/borderColor/fillColor/
//   cutSizeTL 来自 Style.control* 控件样式字段（特化字段组）
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例（状态隔离规范）；
// 异步/时序断言一律 tryCompare/tryVerify 轮询（不写固定 sleep）；浮点 fuzzyEq。
//
// 注：本文件不注册 "No ThemeLoader installed" WARN——ThemeDB 是进程级单例，
// 首个触发点在本批次 tst_basiclabel.qml::test_backgroundCutCorners（文件按名
// 排序先执行）；若未来批次顺序变化导致本文件先触发，需把注册移到新的首个触发点。

TestCase {
    id: root

    name: "QoolBGBox"
    width: 400
    height: 300

    // 确定性几何场景：200×120、四角 cut 20、边框 2——无溢出（used = 期望尺寸），
    // control.leftSpace/rightSpace/bottomSpace = 20
    Component {
        id: bgBoxComp
        QoolBGBox {
            width: 200
            height: 120
            settings: QoolBoxSettings {
                cutSizeTL: 20
                cutSizeTR: 20
                cutSizeBL: 20
                cutSizeBR: 20
                borderWidth: 2
            }
        }
    }

    // 有标签形态专用：visible 是 effective 可见性（含窗口）——offscreen
    // 测试无窗口时恒不可见，QoolBGBox 内部经 label.visible 判断标签是否
    // 参与 space 计算（无窗口 = 恒无标签分支）——须 Window 显示才能测
    // 有标签分支。
    Component {
        id: bgBoxWindowComp
        Window {
            visible: true
            width: 400
            height: 300
            property alias bg: bg
            QoolBGBox {
                id: bg
                width: 200
                height: 120
                settings: QoolBoxSettings {
                    cutSizeTL: 20
                    cutSizeTR: 20
                    cutSizeBL: 20
                    cutSizeBR: 20
                    borderWidth: 2
                }
            }
        }
    }

    // 对照组件：普通 QoolBox（*Space 直接转发 control，无覆盖语义）
    Component {
        id: qoolBoxComp
        QoolBox {
            width: 200
            height: 120
            settings: QoolBoxSettings {
                cutSizeTL: 20
                cutSizeTR: 20
                cutSizeBL: 20
                cutSizeBR: 20
                borderWidth: 2
            }
        }
    }

    // 默认 settings（不覆盖）：核对 Style.control* 显式特化
    Component {
        id: styleDefaultComp
        QoolBGBox {
            width: 200
            height: 120
        }
    }

    function fuzzyEq(a, b, eps) {
        return Math.abs(a - b) <= (eps === undefined ? 1e-6 : eps)
    }

    // 无标签形态（label 未设置）：默认标签存在但空文本不可见，
    // top/bottomSpace 仅为边框宽、left/rightSpace = control 值 + 边框宽
    function test_defaultLabelSpaces() {
        const bg = createTemporaryObject(bgBoxComp, root, {})
        verify(bg.label !== null)
        compare(bg.label.text, "")
        tryCompare(bg.label, "visible", false, 1000)
        tryCompare(bg.control, "leftSpace", 20, 1000) // 几何先决：无溢出
        tryCompare(bg, "topSpace", 2, 1000)
        tryCompare(bg, "bottomSpace", 2, 1000)
        tryCompare(bg, "leftSpace", 22, 1000)
        tryCompare(bg, "rightSpace", 22, 1000)
    }

    // label 空文本（title: ""）与未设置等价：一律无标签形态
    function test_emptyTitleSpaces() {
        const bg = createTemporaryObject(bgBoxComp, root, { title: "" })
        tryCompare(bg.label, "visible", false, 1000)
        tryCompare(bg, "topSpace", 2, 1000)
        tryCompare(bg, "bottomSpace", 2, 1000)
        tryCompare(bg, "leftSpace", 22, 1000)
        tryCompare(bg, "rightSpace", 22, 1000)
    }

    // 有 label 形态：topSpace = 标签高 + 边框宽；left/rightSpace 收紧为边框宽；
    // bottomSpace = control.bottomSpace + 边框宽
    function test_labelVisibleSpaces() {
        const w = createTemporaryObject(bgBoxWindowComp, root, {})
        const bg = w.bg
        bg.title = "Hello"
        tryCompare(bg.label, "visible", true, 1000)
        // 标签行高经异步布局确定——轮询关系式（不依赖具体字体度量）
        tryVerify(function () {
            return fuzzyEq(bg.topSpace, bg.label.height + bg.settings.borderWidth)
        }, 1000)
        tryCompare(bg, "leftSpace", 2, 1000)
        tryCompare(bg, "rightSpace", 2, 1000)
        tryCompare(bg, "bottomSpace", bg.control.bottomSpace + 2, 1000)
    }

    // 覆盖语义：label 可见时 QoolBGBox 的 left/rightSpace 收紧为边框宽，
    // 与 QoolBox 转发 control 的值（20）不同——同系同类覆盖为期望行为
    function test_overrideSemantics() {
        const w = createTemporaryObject(bgBoxWindowComp, root, {})
        const bg = w.bg
        bg.title = "Hello"
        const box = createTemporaryObject(qoolBoxComp, root, {})
        tryCompare(bg.label, "visible", true, 1000)
        tryCompare(bg.control, "leftSpace", 20, 1000)
        tryCompare(box, "leftSpace", 20, 1000) // QoolBox 转发 control
        tryCompare(bg, "leftSpace", 2, 1000) // QoolBGBox 覆盖
        tryCompare(bg, "rightSpace", 2, 1000)
    }

    // settings 显式特化：默认 settings 四字段组来自 Style.control* 控件样式字段
    function test_settingsStyleDefaults() {
        const bg = createTemporaryObject(styleDefaultComp, root, {})
        tryCompare(bg.settings, "borderWidth", Style.controlBorderWidth, 1000)
        compare(bg.settings.borderColor, Style.controlBorderColor)
        compare(bg.settings.fillColor, Style.controlBackgroundColor)
        compare(bg.settings.cutSizeTL, Style.controlCutSize)
    }

    // title 动态切换：无标签 ↔ 有标签形态实时切换，清空 title 安全回退
    function test_titleToggle() {
        const w = createTemporaryObject(bgBoxWindowComp, root, {})
        const bg = w.bg
        tryCompare(bg, "leftSpace", 22, 1000) // 无标签形态
        bg.title = "Hi"
        tryCompare(bg.label, "visible", true, 1000)
        tryCompare(bg, "leftSpace", 2, 1000) // 有标签形态
        bg.title = ""
        tryCompare(bg.label, "visible", false, 1000)
        tryCompare(bg, "leftSpace", 22, 1000) // 回退无标签形态
    }

    // label 显式置 null 空安全：?. 短路，一律按无标签处理
    function test_nullLabelSafe() {
        const bg = createTemporaryObject(bgBoxComp, root, {})
        tryCompare(bg.control, "leftSpace", 20, 1000)
        bg.label = null
        verify(bg.label === null)
        tryCompare(bg, "topSpace", 2, 1000)
        tryCompare(bg, "bottomSpace", 2, 1000)
        tryCompare(bg, "leftSpace", 22, 1000)
        tryCompare(bg, "rightSpace", 22, 1000)
    }
}
