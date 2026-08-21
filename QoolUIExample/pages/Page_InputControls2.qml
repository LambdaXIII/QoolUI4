// 输入控件（二）：Slider + Dial 展示页。
//
// 用例梳理自 Playground 的 Slider 调试场：相关主题合并进
// 同一 QoolControl（反馈/官方行为/尺寸形态各一组），每组内多 Slider 并排；
// QoolTip 详尽说明行为、属性与注意点。Dial 为 Qool.Controls 现有组件
// （T.Dial 模板 + 三色弧），在此补充正式展示。
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qool
import Qool.Controls
import Qool.Controls.Components

import "components"

BasicPage {
    id: root

    title: qsTr("输入控件（二）")
    note: qsTr("Slider / RangeSlider 与 Dial——滑块、区间滑块与转盘")

    implicitHeight: cc.implicitHeight

    // 行为插拔示例组件：自定义端点窄条（模板 handle 插拔契约——替换
    // first/second.handle 即自定义端点命中/视觉/光标；定位须自写——
    // 模板不注入 handle 位置，窄条不相交公式与默认 handle 同款）。
    component HandleKnob: Rectangle {
        required property RangeSlider owner
        required property var endpoint
        required property bool isSecond
        width: height / 2
        height: owner.availableHeight
        radius: height / 4
        color: Qt.alpha(owner.Style.accent, 0.55)
        border.color: owner.Style.accent
        x: owner.leftPadding + (isSecond ? width : 0)
            + endpoint.visualPosition * (owner.availableWidth - width * 2)
        y: owner.topPadding + owner.availableHeight / 2 - height / 2
        // 仅光标反馈：NoButton 不拦截按压（模板拖动经 handle 命中有效）
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.SizeHorCursor
        }
    }

    Column {
        id: cc

        spacing: 25

        // —— 基础 Slider ——
        QoolControl {
            title: qsTr("基础 Slider")
            width: 260
            contentItem: Slider {
                id: basicSlider
                from: 0
                to: 100
                value: 50
            }
            QoolTip {
                text: qsTr("水平滑块：六边形渐变轨道（**Style.buttonText 75% 透明 → Style.accent** 水平渐变，锚定切角内侧）+ 水晶菱形手柄（同一八点模型——斜边斜率一致天然对齐）。\n交互为官方模板行为：点击跳转、拖动连续、方向键步进（获得焦点后）。\n- **配色经统一样式接口**（控件不设实例色属性）：渐变右端 = Style.accent、渐变左端 = Style.buttonText（Qt palette 名，实义 control 前景色，轨道 75% 透明渲染）、描边 = recommendForeground(buttonText) 自动对比——换色经 Style 附着传播（Style.accent / Style.buttonText 挂本实例或任意祖先）。\n- 默认 150×25（implicit，可覆盖 width/height）——手柄尺寸始终跟随控件实际高度（轨道与手柄常态同高）。\n- 手柄常态色 = 轨道渐变在当前值位置的采样色但不透明化（ColorMapper.colorAt——拖动时实时变化；轨道端半透明、手柄为实体）。")
            }
        }

        // —— 交互反馈：上手反馈（hover 展开/光标/提亮）+ 程序化锁存 ——
        QoolControl {
            title: qsTr("交互反馈")
            width: 260
            contentItem: ColumnLayout {
                spacing: 12
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 30
                }
                Slider {
                    id: progSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 20
                }
                Timer {
                    interval: 1500
                    running: true
                    repeat: true
                    onTriggered: progSlider.value = (progSlider.value + 25) % 101
                }
            }
            QoolTip {
                text: qsTr("两套反馈语言：\n**上手反馈**（上）——悬停：光标变水平双向箭头（仅 enabled 时）、手柄展开到控件全高（常态收缩 limit(高度×0.25, 3, 25)——视觉差即放大反馈；轨道与手柄常态同高、中心对齐）；按下/值变化（movementDuration×2 锁存窗口）手柄保持展开。动画随 animationEnabled 门控（父链继承，回退 Style）。\n**程序化锁存**（下）——外部定时器每 1.5s 写入 value：每次变化后手柄展开约 movementDuration×2（TimerLatch 锁存窗口）再回落——“值被写入即反馈”（无论谁写的；持续变化期间窗口滑动保持）。\n- 手柄常态收缩、展开占满控件高度（不超出边界）——clip 与否不影响反馈。")
            }
        }

        // —— 官方行为：倒置范围 / 禁用 / 键盘步进 ——
        QoolControl {
            title: qsTr("官方行为")
            width: 260
            contentItem: ColumnLayout {
                spacing: 8
                BasicControlText {
                    text: qsTr("倒置范围（from > to）")
                    Layout.fillWidth: true
                }
                Slider {
                    Layout.fillWidth: true
                    from: 100
                    to: 0
                    value: 75
                }
                BasicControlText {
                    text: qsTr("禁用（enabled = false）")
                    Layout.fillWidth: true
                }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 60
                    enabled: false
                }
                BasicControlText {
                    text: qsTr("键盘步进（stepSize = 5）")
                    Layout.fillWidth: true
                }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    stepSize: 5
                    value: 50
                }
            }
            QoolTip {
                text: qsTr("三组官方代数/状态行为：\n- **倒置范围**：from > to 刻度反向——拖动到右侧值减小；increase() 增大实际值、视觉向 to 端移动。渐变与手柄采样自动跟随 visualPosition 反向（刻度反向是设计，非缺陷）。\n- **禁用**：enabled = false 保持常态外观——无光标反馈、无悬停展开；程序化写入也不再展开（resizer 门控随 enabled——禁用视觉静态化）。\n- **键盘步进**：stepSize = 5——点击获得焦点后方向键按 5 步进（官方键盘行为）。")
            }
        }

        // —— 尺寸形态：八点模型三形态（高轨道六边形 / 瘦轨道瘦六边形）——
        QoolControl {
            title: qsTr("尺寸形态")
            width: 260
            contentItem: ColumnLayout {
                spacing: 12
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 50
                    implicitHeight: 80
                }
                Slider {
                    Layout.fillWidth: false
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 120
                    Layout.alignment: Qt.AlignHCenter
                    from: 0
                    to: 100
                    value: 40
                }
            }
            QoolTip {
                text: qsTr("水晶八点模型（OctagonShape 特化——切角 = shortEdge/2）的形态覆盖：\n- **高轨道**（上，80px）：宽六边形（w > h）——切角随高度变（shortEdge/2），渐变锚定中线；手柄常态与轨道同高（顶点贴斜边）、展开占满控件全高。\n- **瘦轨道**（下，40×120）：**w < h 时六边形自然闭合为瘦六边形**（上下尖 + 左右直边）——可直接作竖直滑块背景；本用例交互仍为水平语义（几何形态展示）。\n- 中间态 w = h 为菱形（旋转 45° 正方形）——同模型统一路径，无需分支。\n- 手柄常态收缩、展开占满控件高度（不超出边界）。")
            }
        }

        // —— 插拔替换：轨道色 / 手柄 ——
        QoolControl {
            title: qsTr("插拔替换")
            width: 300
            contentItem: ColumnLayout {
                Slider {
                    id: shellSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 40
                    // 换色经 Style 附着传播（挂本实例——单实例粒度）
                    Style.accent: "#ff8800"
                }
                Slider {
                    id: customHandleSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 70
                    handle: Rectangle {
                        width: 12
                        height: customHandleSlider.availableHeight
                        radius: 2
                        color: customHandleSlider.Style.accent
                        x: customHandleSlider.leftPadding + customHandleSlider.visualPosition * (customHandleSlider.availableWidth - width)
                        y: customHandleSlider.topPadding + (customHandleSlider.availableHeight - height) / 2
                    }
                }
            }
            QoolTip {
                text: qsTr("两处独立替换：\n- **Style.accent**（上）——经 Style 附着传播换渐变右端色，手柄采样自动跟随——宿主无需碰手柄。\n- **自定义 handle**（下）——替换水晶菱形（矩形手柄）；**handle delegate 须自写 x/y 定位**（T.Slider 模板不注入定位——官方公式：x = leftPadding + visualPosition * (availableWidth - width)，y 同理垂直居中）。\n- 轨道渐变内联默认（Style.buttonText 75% 透明 → Style.accent，锚定切角内侧）；配色经 Style 附着传播（右端 accent / 左端 buttonText / 描边自动对比）；轨道尺寸经标准自动布局（root − insets）——替换 background 后新实例同样受控。")
            }
        }

        // —— RangeSlider：区间滑块（模板 handle 体系 + 区间盒前景）——
        QoolControl {
            title: qsTr("RangeSlider 区间滑块")
            width: 260
            contentItem: ColumnLayout {
                spacing: 12
                RangeSlider {
                    id: rangeSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    // 官方契约：setValues() 一次性写入（first/second 有循环
                    // 依赖——分别赋值可能互相钳制）
                    Component.onCompleted: setValues(25, 75)
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("范围：%1 – %2").arg(Math.round(rangeSlider.first.value)).arg(Math.round(rangeSlider.second.value))
                    color: Style.text
                }
                // 垂直：orientation × RTL 正交适配（ADR-0011）——handle 窄条
                // 换向横置、不相交公式随轴换、区间盒纵向映射、implicit 交换
                RowLayout {
                    Layout.fillWidth: true
                    RangeSlider {
                        id: vertRangeSlider
                        orientation: Qt.Vertical
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 120
                        from: 0
                        to: 100
                        Component.onCompleted: setValues(25, 75)
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: qsTr("垂直：%1 – %2").arg(Math.round(vertRangeSlider.first.value)).arg(Math.round(vertRangeSlider.second.value))
                            color: Style.text
                        }
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: qsTr("瘦轨道 + 横置窄条 handle + 纵向区间盒；implicit 交换 25×150")
                            color: Style.mid
                            font.pixelSize: 12
                        }
                    }
                }
                RangeSlider {
                    id: progRangeSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    Component.onCompleted: setValues(20, 80)
                }
                Timer {
                    interval: 1500
                    running: true
                    repeat: true
                    onTriggered: {
                        const v = (progRangeSlider.first.value + 15) % 101;
                        progRangeSlider.setValues(v, Math.min(v + 40, 100));
                    }
                }
            }
            QoolTip {
                text: qsTr("RangeSlider：**T.RangeSlider 模板 + 默认窄条 handle**（激活模板交互——**snapMode/stepSize/live/键盘/nearest/端点钳制全部为模板行为**）+ **Crystal 轨道**（Style.buttonText 75% 透明 + recommend 描边，静态不参与交互反馈）+ **contentItem 内区间盒前景**（rangeBox 承载区间几何，hover 展开）。\n**交互**：双端点拖动（模板 handle 命中即拖）；**snap/live 为模板语义**（吸附 / 拖动中值实时性 / 释放落定全由模板承担）；点击轨道走模板 nearest（跳最近端点）。\n**反馈**：**hover 前景**（rangeBox 内 HoverHandler）→ 前景展开占满区间盒（常态 = 收缩量 limit(side×0.25, 3, 25)——side = 法向尺寸，ItemAnimatedResizer 动画——animationEnabled 门控）。\n**插拔**：`first.handle`/`second.handle` 替换 ＝行为插拔（模板 handle 契约，定位自写：窄条不相交公式）。\n**orientation×RTL**：`orientation: Qt.Vertical` 正交适配（ADR-0011，同 Slider）——handle 窄条换向横置、不相交公式随轴换（行程 = 可用高 − 高×2）、区间盒纵向映射 + 尖角余量换自身宽、implicit 交换 25×150、光标 SplitVCursor；RTL 由 visualPosition 免费承载（垂直不受 RTL 影响，值大恒在顶）。\n**整体滑移**（中段拖动区间整体移动）非默认能力——宿主自建（contentItem 内 MouseArea 同步操作两端）。")
            }
        }

        // —— RangeSlider 插拔：外观 / 行为 ——
        QoolControl {
            title: qsTr("RangeSlider 插拔")
            width: 300
            contentItem: ColumnLayout {
                spacing: 12
                RangeSlider {
                    id: customColorSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    // 外观经 Style 附着传播：Style.accent 前景 / Style.buttonText
                    // 轨道（描边 = recommendForeground(buttonText) 自动对比）
                    Style.accent: Style.active.accent
                    Style.buttonText: Style.active.base
                }
                RangeSlider {
                    id: customHandleSlider2
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    // 行为插拔：替换 first/second.handle（模板 handle 插拔
                    // 契约）——自定义端点命中/视觉/光标；替换后 snap/live/
                    // 键盘仍为模板行为
                    first.handle: HandleKnob {
                        owner: customHandleSlider2
                        endpoint: customHandleSlider2.first
                        isSecond: false
                    }
                    second.handle: HandleKnob {
                        owner: customHandleSlider2
                        endpoint: customHandleSlider2.second
                        isSecond: true
                    }
                }
            }
            QoolTip {
                text: qsTr("两组定制（互不影响）：\n- **外观通道**（上）——经 Style 附着传播换 `Style.accent`（前景）/`Style.buttonText`（轨道，描边自动对比），宿主无需碰结构。\n- **行为插拔**（下）——替换 `first.handle`/`second.handle`（模板 handle 插拔契约）：自定义端点命中/视觉/光标；**定位须自写**（模板不注入）——窄条不相交公式 `x = leftPadding + (second? width:0) + visualPosition × (availableWidth − width×2)`（两个 handle 各自占 width，永不相交）；替换后 snap/live/键盘仍为模板行为。")
            }
        }

        // —— 基础件：TimerLatch / NumberNotifier ——
        QoolControl {
            title: qsTr("基础件")
            width: 300
            contentItem: ColumnLayout {
                spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: qsTr("触发锁存")
                        onClicked: demoLatch.trigger()
                    }
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 4
                        color: demoLatch.active ? Style.highlight : Style.mid
                        BasicColorBehavior on color {}
                    }
                    Text {
                        text: qsTr("active: %1").arg(demoLatch.active)
                        color: Style.text
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("NumberNotifier 观测基础 Slider 的 value——当前速率：%1 值/秒").arg(demoNotifier.velocity.toFixed(1))
                    color: Style.text
                }
            }
            // 逻辑件（无视觉——不入布局容器）
            TimerLatch {
                id: demoLatch
                interval: 1000
            }
            NumberNotifier {
                id: demoNotifier
                target: basicSlider
                property: "value"
            }
            QoolTip {
                text: qsTr("Slider 反馈语言的底层逻辑件（独立可复用，Qool 模块）：\n- **TimerLatch**：trigger() → active 锁存 interval（默认 1000ms）后自动释放——滑动窗口（持续触发持续保持）；activated/deactivated 信号；任意信号源可触发（本例为按钮）。\n- **NumberNotifier**：每 interval（默认 200ms）采样 target 属性 → velocity（值/秒、有向、骤停归零）——“转速表”语义；valueUpdated(newValue, oldValue) 为采样快照（延迟 ≤ interval，可能错过往返——与属性自身的 Changed 不同）。")
            }
        }

        // —— Dial 转盘 ——
        QoolControl {
            title: qsTr("Dial 转盘")
            width: 260
            contentItem: Dial {
                id: dial
                implicitWidth: 120
                implicitHeight: 120
                from: 0
                to: 100
                value: 60
            }
            QoolTip {
                text: qsTr("Dial 转盘（Qool.Controls——T.Dial 模板）：拖动圆周/方向键调节角度值。\n- 视觉：圆形轨道（controlBackgroundColor 底 + buttonText 边框）+ 指针手柄；按住时弧段高亮（highColor→midColor→lowColor 映射当前位置——默认 red/yellow/green）且手柄变为位置色（ColorMapper 采样）。\n- 属性：from/to/value/position 为官方 API；highColor/midColor/lowColor 三色映射可自定义。")
            }
        }
    } //cc
}
