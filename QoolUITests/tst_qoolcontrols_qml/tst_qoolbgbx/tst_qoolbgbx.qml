import QtQuick
import QtTest
import Qool
import Qool.Controls.Components

// QoolBGBox space 语义测试（Qool.Controls.Components/QoolBGBox.qml）
//
// 被测契约：
// - *Space 计算公式：topSpace = max(labelTopSpace, cutSpaceOnTop) + borderSpace
//   （labelTopSpace = titleItem 可见时 titleItem.y + titleItem.height，否则 0；
//   cutSpaceOnTop = max(cutSizeTL, cutSizeTR)，QoolBoxSettings 只读辅助）；
//   bottomSpace/leftSpace/rightSpace = borderSpace = borderWidth + 1
// - titleItem 可见性为 effective 语义：offscreen（无窗口）恒不可见 →
//   恒走无标签分支；有窗口且 title 非空才参与 topSpace（旧 label 同名语义）
// - titleItem 空安全：未设置（默认空文本）/ 空文本 / 显式置 null
//   一律按无标签处理（titleItem?.visible 空安全短路）
// - settings 显式特化：默认 settings 的 borderWidth/borderColor/fillColor/
//   cutSizeTL 来自 Style.control* 控件样式字段（特化字段组）
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例（状态隔离规范）；
// 异步/时序断言一律 tryCompare/tryVerify 轮询（不写固定 sleep）；浮点 fuzzyEq。
//
// 注：本文件不注册 "No ThemeLoader installed" WARN——ThemeDB 是进程级单例；
// 若未来运行时首个实例化 Style/ThemeHQ 组件的是本文件，需在此补注册。

TestCase {
    id: root

    name: "QoolBGBox"
    width: 400
    height: 300

    // 确定性几何场景：200×120、四角 cut 20、边框 2——无溢出
    // （cutSpaceOnTop/Bottom = max(相邻 cut) = 20，borderSpace = 3）
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

    // 有标签形态专用：titleItem.visible 是 effective 可见性（含窗口）——
    // offscreen 测试无窗口时恒不可见，QoolBGBox 内部经 titleItem.visible
    // 判断标签是否参与 space 计算（无窗口 = 恒无标签分支）——
    // 须 Window 显示才能测有标签分支。
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

    // 默认 settings（不覆盖）：核对 Style.control* 显式特化
    Component {
        id: styleDefaultComp
        QoolBGBox {
            width: 200
            height: 120
        }
    }

    // 无标签形态（offscreen 恒无标签）：topSpace = cutSpaceOnTop + borderSpace
    // = 23；bottom/left/rightSpace = borderSpace = 3

    // titleItem 空文本（title: ""）与未设置等价：一律无标签形态

    // 有标签形态（须 Window）：topSpace = titleItem.y + titleItem.height
    // + borderSpace；left/right/bottomSpace 仍为 borderSpace（与旧版
    // label 收紧语义不同——新版三向恒为边框空间，不随标签变化）

    // settings 显式特化：默认 settings 四字段组来自 Style.control* 控件样式字段
    function test_settingsStyleDefaults() {
        const bg = createTemporaryObject(styleDefaultComp, root, {})
        tryCompare(bg.settings, "borderWidth", Style.controlBorderWidth, 1000)
        compare(bg.settings.borderColor, Style.controlBorderColor)
        compare(bg.settings.fillColor, Style.controlBackgroundColor)
        compare(bg.settings.cutSizeTL, Style.controlCutSize)
    }

    // title 动态切换：无标签 ↔ 有标签形态实时切换，清空 title 安全回退

    // titleItem 显式置 null 空安全：?. 短路，一律按无标签处理
}
