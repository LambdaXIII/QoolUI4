// Playground：测试场——Qool.Controls 控件的展示性实现与调试用例（仓库
// 开发模式：可随意更改，不保留旧内容）。
//
// 当前内容：Qool.Controls.Slider 展示用例（2026-08-10 重写——旧 TextField/
// SpinBox 调试用例已清空；TextField 展示已整合 Page_InputControls）。
import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import Qool.Controls.Components
import QtQuick.Layouts
import "components"

BasicPage {
    id: root

    title: qsTr("Slider 测试场")
    note: qsTr("Qool.Controls.Slider——拖动/点击/键盘/反馈/倒置/插拔展示用例")

    implicitHeight: cc.implicitHeight

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
                text: qsTr("点击/拖动整框任意位置调节（无手柄）；右侧小字显示数值（最多 3 位小数、去尾零去点）——文字颜色随填充边界分区：透明区段主题前景色、填充区段按亮度计算的对比色。")
            }
        }

        // —— 交互反馈 ——
        QoolControl {
            title: qsTr("交互反馈")
            width: 260
            contentItem: Slider {
                from: 0
                to: 100
                value: 30
            }
            QoolTip {
                text: qsTr("hover（enabled）：光标变为水平双向箭头（不变色）；按下或值运动锁存期间：填充提亮（lighter 1.4）——动画随 Style.animationEnabled 门控。")
            }
        }

        // —— 程序化变化 + TimerLatch 锁存反馈 ——
        QoolControl {
            title: qsTr("程序化变化 + 锁存反馈")
            width: 260
            contentItem: Slider {
                id: progSlider
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
            QoolTip {
                text: qsTr("外部定时器每 1.5s 写入 value——每次变化后填充短暂提亮约 1s（TimerLatch 锁存窗口）再回落——与拖动同款反馈语言（无论谁写的）。")
            }
        }

        SectionBar {
            width: parent.width
        }

        // —— 倒置范围 ——
        QoolControl {
            title: qsTr("倒置范围")
            width: 260
            contentItem: Slider {
                from: 100
                to: 0
                value: 75
            }
            QoolTip {
                text: qsTr("from>to 刻度反向：拖动到右侧值减小；increase() 增大实际值、视觉向 to 端移动（官方代数语义——刻度反向是设计，非缺陷）。")
            }
        }

        // —— 禁用 ——
        QoolControl {
            title: qsTr("禁用")
            width: 260
            contentItem: Slider {
                from: 0
                to: 100
                value: 60
                enabled: false
            }
            QoolTip {
                text: qsTr("enabled=false：常态外观；hover 无光标反馈、按下无提亮（disabled 不响应交互）。")
            }
        }

        // —— 键盘步进 ——
        QoolControl {
            title: qsTr("键盘步进")
            width: 260
            contentItem: Slider {
                from: 0
                to: 100
                stepSize: 5
                value: 50
            }
            QoolTip {
                text: qsTr("stepSize=5：点击获得焦点后按方向键按 5 步进（官方键盘行为）。")
            }
        }

        SectionBar {
            width: parent.width
        }

        // —— 插拔替换：两视觉层独立替换 ——
        QoolControl {
            title: qsTr("插拔替换")
            width: 300
            contentItem: ColumnLayout {
                // 上：自定义 background（不透明壳），默认 handle（填充+文字）保留
                Slider {
                    id: shellSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 40
                    background: Rectangle {
                        z: 0
                        width: shellSlider.width
                        height: 6
                        y: (shellSlider.height - height) / 2
                        color: "#335577"
                        radius: 2
                    }
                }
                // 下：自定义 handle（替换值显示件——简单填充，无文字），默认外壳保留
                Slider {
                    id: customHandleSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 70
                    handle: Rectangle {
                        z: 1
                        width: customHandleSlider.width
                        height: customHandleSlider.height
                        Rectangle {
                            y: (parent.height - 6) / 2
                            width: customHandleSlider.availableWidth
                                   * customHandleSlider.visualPosition
                            height: 6
                            color: "orange"
                        }
                    }
                }
            }
            QoolTip {
                text: qsTr("两视觉层独立替换：上——自定义 background（不透明壳），默认值显示件保留；下——自定义 handle（纯填充），默认外壳保留——互不破坏。")
            }
        }

        // —— 基础件独立演示 ——
        QoolControl {
            title: qsTr("基础件独立演示")
            width: 300
            contentItem: ColumnLayout {
                spacing: 8
                // TimerLatch：按钮点击触发锁存（任意信号源）
                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: qsTr("触发锁存")
                        onClicked: demoLatch.activate()
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
                // NumberNotifier：观测基础 Slider 的 value——持续速率
                Text {
                    Layout.fillWidth: true
                    text: qsTr("NumberNotifier 观测基础 Slider 的 value——当前速率：%1 值/秒")
                        .arg(demoNotifier.velocity.toFixed(1))
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
                text: qsTr("TimerLatch：任何信号触发 → 锁存 interval 后自动释放（滑动窗口——持续触发持续保持）；NumberNotifier：每 interval（默认 200ms）采样 → velocity（值/秒、有向、骤停归零）。")
            }
        }
    } //cc
}
