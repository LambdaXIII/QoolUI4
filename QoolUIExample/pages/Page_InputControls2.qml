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

    // 行为插拔示例组件：继承 RangeHandle 覆盖行为（默认实现即三区域拖动；
    // 此处演示派生类替换后完整获得配套绑定——覆盖任意行为即插拔）。
    component LoggingHandle: RangeHandle {
        // 行为覆盖示例：记录拖动信号载荷（不改变默认交互）
        onFirstMoved: pos => console.log("firstMoved", pos)
        onSecondMoved: pos => console.log("secondMoved", pos)
        onRangeMoved: delta => console.log("rangeMoved", delta)
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
                text: qsTr("水平滑块：六边形渐变轨道（**text→color** 水平渐变，锚定切角内侧）+ 水晶菱形手柄（同一八点模型——斜边斜率一致天然对齐）。\n交互为官方模板行为：点击跳转、拖动连续、方向键步进（获得焦点后）。\n- **color** = 渐变右端色（默认 Style.accent，左端固定 Style.text）——换色即换整条轨道视觉。\n- 默认高度 25（implicitHeight，可覆盖 width/height）——手柄尺寸始终跟随控件实际高度（轨道与手柄常态同高）。\n- 手柄常态色 = 轨道渐变在当前值位置的采样色（ColorMapper.colorAt——拖动时实时变化）。")
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
                text: qsTr("两套反馈语言：\n**上手反馈**（上）——悬停：光标变水平双向箭头（仅 enabled 时）、手柄展开到控件全高（常态收缩 limit(高度×0.25, 3, 25)——视觉差即放大反馈；轨道与手柄常态同高、中心对齐）；按下/刚移动（值变化 500ms 内）手柄保持展开。动画随 animationEnabled 门控（父链继承，回退 Style）。\n**程序化锁存**（下）——外部定时器每 1.5s 写入 value：每次变化后手柄展开约 500ms（TimerLatch 锁存窗口）再回落——“值被写入即反馈”（无论谁写的；持续变化期间窗口经 valueVelocity 采样级重置不落，禁用时程序化写入也展开）。\n- 手柄常态收缩、展开占满控件高度（不超出边界）——clip 与否不影响反馈。")
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
                text: qsTr("三组官方代数/状态行为：\n- **倒置范围**：from > to 刻度反向——拖动到右侧值减小；increase() 增大实际值、视觉向 to 端移动。渐变与手柄采样自动跟随 visualPosition 反向（刻度反向是设计，非缺陷）。\n- **禁用**：enabled = false 保持常态外观——无光标反馈、无悬停展开；程序化写入的展开反馈仍保留（数据反馈不随交互禁用）。\n- **键盘步进**：stepSize = 5——点击获得焦点后方向键按 5 步进（官方键盘行为）。")
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
                text: qsTr("水晶八点模型（OctagonShape 特化——切角 = shortEdge/2）的形态覆盖：\n- **高轨道**（上，80px）：宽六边形（w > h）——切角随高度变（shortEdge/2），渐变锚定中线；手柄常态与轨道同高（顶点贴斜边）、展开占满控件全高。\n- **瘦轨道**（下，40×120）：**w < h 时六边形自然闭合为瘦六边形**（上下尖 + 左右直边）——可直接作竖直滑块（VerticalSlider）的背景；本用例交互仍为水平语义（几何形态展示）。\n- 中间态 w = h 为菱形（旋转 45° 正方形）——同模型统一路径，无需分支。\n- 手柄常态收缩、展开占满控件高度（不超出边界）。")
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
                    color: "#ff8800"
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
                        color: customHandleSlider.color
                        x: customHandleSlider.leftPadding + customHandleSlider.visualPosition * (customHandleSlider.availableWidth - width)
                        y: customHandleSlider.topPadding + (customHandleSlider.availableHeight - height) / 2
                    }
                }
            }
            QoolTip {
                text: qsTr("两处独立替换：\n- **color 属性**（上）——换渐变右端色（默认 Style.accent），手柄采样自动跟随——宿主无需碰手柄。\n- **自定义 handle**（下）——替换水晶菱形（矩形手柄）；**handle delegate 须自写 x/y 定位**（T.Slider 模板不注入定位——官方公式：x = leftPadding + visualPosition * (availableWidth - width)，y 同理垂直居中）。\n- 轨道渐变内联默认（text→color，锚定切角内侧）——整体替换不再提供（收缩决策）；换色走 **color** 属性。")
            }
        }

        // —— RangeSlider：区间滑块（三层结构）——
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
                        const v = (progRangeSlider.first.value + 15) % 101
                        progRangeSlider.setValues(v, Math.min(v + 40, 100))
                    }
                }
            }
            QoolTip {
                text: qsTr("RangeSlider 三层结构：**值模型 + 静态背景**（T.RangeSlider 模板 + Crystal 六边形轨道，Style.text 1 色非渐变——不参与交互反馈）→ **RangeHandle**（区间逻辑单一归属：空间位置/三区域交互/surface 布局）→ **surface**（默认 Crystal 整体前景——左尖角 + 中段填充 + 右尖角，两端点重合自动退化为水晶菱形）。\n**三区域拖动**：左端区拖 first、右端区拖 second、中段区拖**整体滑移**（两端同步、区间宽不变、边界钳制整体停）；**全部点击无操作**（模板\"点击跳转\"不保留）；键盘保留模板行为。\n**反馈**：hover/按下/刚移动（justMoved 锁存 500ms——下方 Timer 程序化写入演示）→ 前景展开到控件全高（常态 = preferredHeight 收缩，垂直居中、宽度不变）；动画随 animationEnabled 门控。\n**插拔**：`rangeHandle` 属性替换（继承 RangeHandle）＝行为插拔；`rangeHandle.surface` 替换任意 Item ＝外观插拔——两层独立互不影响。")
            }
        }

        // —— RangeSlider 插拔：外观 / 行为 ——
        QoolControl {
            title: qsTr("RangeSlider 插拔")
            width: 300
            contentItem: ColumnLayout {
                spacing: 12
                RangeSlider {
                    id: customSurfaceSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    // 外观插拔：替换 surface 为任意 Item——布局（位置/尺寸/
                    // 颜色）由 RangeHandle 统一施加，自动填充正确区间，宿主
                    // 无需自算值→位置映射
                    rangeHandle: RangeHandle {
                        surface: Rectangle {
                            radius: 3
                            color: customSurfaceSlider.color
                            border.color: Style.highlight
                            border.width: 1
                        }
                    }
                }
                RangeSlider {
                    id: customHandleSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    // 行为插拔：继承 RangeHandle 覆盖行为后替换（此处演示
                    // 继承替换仍获得全部配套绑定——三区域拖动/展开反馈
                    // 完整保留）
                    rangeHandle: LoggingHandle {}
                }
            }
            QoolTip {
                text: qsTr("两层独立插拔（互不影响）：\n- **外观插拔**（上）——`rangeHandle.surface` 替换任意 Item：RangeHandle 对 surface 施加 x/y/width/height/color 绑定（x = firstPosition − cutSize、宽 = 区间宽 + 2×cutSize 尖角溢出、高 = 展开/常态切换、色 = color）——\"任意简单 Item 即自动填充区间\"；需精确 fill（无尖角溢出）时置 `cutSize: 0`。\n- **行为插拔**（下）——继承 RangeHandle 的派生组件（LoggingHandle）替换 `rangeHandle` 属性：配套绑定（位置/展开源/颜色/动画门控）与信号换算经动态 Binding/Connections 施加——替换实例同样受控，覆盖行为即插拔。\n- 两层互不依赖：换外观不丢交互、换行为不丢外观。")
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
