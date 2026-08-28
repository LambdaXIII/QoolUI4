// Qool.Controls.Slider：水晶六边形渐变轨道 + 菱形手柄的滑块（水平/垂直 + RTL）
// （T.Slider 模板 API 兼容）。
//
// 结构：模板 handle（激活模板交互——点击跳转/拖动连续/键盘步进/倒置范围
// 免费）+ Crystal 渐变轨道（background，静态）+ handle 内前景 Crystal
// （hover/按下/值变化锁存展开动画）。轨道渐变与手柄采样色同源——换 Style
// 配色即换整条视觉。
//
// 完整契约（几何模型/交互反馈/属性/易误解点）见
// docs/reference/Qool.Controls/Slider.md。

import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import Qool
import Qool.Controls.Components

T.Slider {
    id: root

    // 尺寸：标准 background 驱动——组件自写 implicit 公式（模板不自带），
    // background 显式 implicit（150×25，与 RangeSlider 统一）供计算；无
    // contentItem（前景在 handle 内、不占控件尺寸）——contentItem 项恒 0，
    // implicit 只由 background 项决定。
    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    SmartObject {
        id: pCtrl
        // 法向尺寸抽象：轨道法向尺寸——水平时 = 可用高（垂直轴）、垂直时 =
        // 可用宽（水平轴）。横竖对称、镜像无关（收缩居中不随镜像变化）；
        // 手柄边长/收缩量/轨道收缩/展开全部基于它。
        readonly property real side: root.horizontal ? root.availableHeight : root.availableWidth
        // 常态收缩量：轨道与手柄从全尺寸收缩的量（hover/按下/锁存展开时
        // 手柄占满法向；轨道恒为常态——静态，不参与交互反馈）。轨道宽高
        // 双向各收缩此量（保证收缩态 handle 与轨道正确对齐）。
        readonly property real shrinkSize: Qore.bound(3, side * 0.25, 25)
        // 收缩偏移量的一半——轨道双向居中（收缩后四边各留 shrinkSize/2）。
        readonly property real halfShrinkSpace: shrinkSize / 2
    }

    // —— 轨道（六边形渐变）：Crystal 六边形模型——与手柄同模型、斜边斜率
    // 一致天然对齐（OctagonShape 双层模型——QoolBoxGadget 半平面交集下
    // 切角极限形态合法，Crystal 即 cut = shortEdge/2 特化）。background 显式
    // implicit（150×25）供控件 implicit 计算；尺寸经 Control 标准自动布局
    // （background 自动 fill 控件 − insets，宿主替换新实例同样受控——插拔
    // 安全）。轨道恒为常态尺寸（不随展开变）+ 双向收缩居中——宽高各收缩
    // shrinkSize、x = y = shrinkSize/2（收缩态 handle 与轨道对齐）；三心
    // 对齐：水晶中心 = 轨道中心 = 控件中心（水晶常态与轨道同高贴斜边；
    // 展开时水晶顶出轨道但不出控件）
    background: Item {
        // implicit 随 orientation 交换（水平 150×25 ↔ 垂直 25×150）——对齐
        // 官方"垂直默认窄"惯例；根 implicit 公式本身不变（background 项
        // implicit 自适应）
        implicitWidth: root.horizontal ? 150 : 25
        implicitHeight: root.horizontal ? 25 : 150

        Crystal {
            id: track
            objectName: "track" // 供 QML 测试读取（组件内部对象零暴露原则的测试例外——轨道静态性是公开视觉契约）

            // 无论垂直还是水平，高度和宽度都应该缩减，保证缩减状态的handle正确对齐
            width: parent.width - pCtrl.shrinkSize
            height: parent.height - pCtrl.shrinkSize
            x: pCtrl.halfShrinkSpace
            y: pCtrl.halfShrinkSpace
            // 兜底纯色（渐变通道失效时轨道仍可见——渐进降级；渐变生效时覆盖）
            color: root.Style.accent
            // 焦点高亮：键盘聚焦（visualFocus——仅 Tab/Backtab/Shortcut 键盘
            // 原因聚焦）时边框切换 Style.highlight、失焦恢复
            // ThemeHQ.recommendForeground(Style.buttonText)（自动对比推荐）
            borderColor: root.visualFocus ? root.Style.highlight : ThemeHQ.recommendForeground(root.Style.buttonText)
            // 切换动画门控 animationEnabled（关闭时即时跳变）
            BasicColorBehavior on borderColor {
                enabled: root.Style.animationEnabled
            }
            fillGradient: LinearGradient {
                // 渐变内联默认（不暴露 fillGradient 通道——换色经 Style 附着
                // 传播）：from 端 = Style.buttonText 75% 透明（轨道同
                // RangeSlider——背景色半透明）、to 端 = Style.accent；锚定"值增大
                // 视觉端"（非固定几何端）+ 镜像感知：轴向选 x/y（horizontal）、
                // RTL（root.mirrored）时水平端对调——对调的是 x1/x2 坐标，stop
                // 色序不变（position 0 = from 端 bg、1 = to 端 accent，随坐标
                // 移动；垂直不受 RTL 影响，见坐标处）。cut = 轨道短边/2（Crystal
                // 切角几何，与手柄中心行程一致——colorAt(position) 精确采样）；
                // 坐标用 track 自身尺寸（收缩后切角 = 短边/2）
                readonly property real cut: Math.min(track.width, track.height) / 2
                // 水平：沿 x（x1=cut → x2=w−cut，y 居中），RTL（root.mirrored）
                // 时 x 端对调（值增大端随 handle 移到左）；
                // 垂直：沿 y 恒 from 底 → to 顶——Qt 垂直惯例（值增大 handle
                // 在顶，visualPosition 恒 = 1−position，与 RTL 无关，故不对调）
                x1: root.horizontal ? (root.mirrored ? track.width - cut : cut) : track.width / 2
                y1: root.horizontal ? track.height / 2 : track.height - cut
                x2: root.horizontal ? (root.mirrored ? cut : track.width - cut) : track.width / 2
                y2: root.horizontal ? track.height / 2 : cut
                GradientStop {
                    position: 0
                    color: Qt.alpha(root.Style.buttonText, 0.75)
                }
                GradientStop {
                    position: 1
                    color: root.Style.accent
                }
            }
        }
    } //background

    // —— 手柄（CrystalCursor 本体——ADR-0016 基准件，根即 handle）：
    // 菱形 + 延迟缩放展开（常态 side−shrinkSize、展开 side）+ 色注入
    // （采样色 colorAt）。基准件契约裁剪——定位与长保持锁存归消费方，
    // 消费方在实例上实现（footprint 恒定：缩放只作用内部 Crystal，定位
    // 锚不随缩放偏移）；expanded = hover‖按下‖值变化锁存三态或；
    // delta = shrinkSize（常态收缩贴轨道、展开顶出轨道但不出控件）。
    handle: CrystalCursor {
        id: cursor
        // 边长 = 轨道法向（side）：水平 = 可用高、垂直 = 可用宽——菱形恒等，
        // 横竖对称（法向居中不随镜像变化）
        width: pCtrl.side
        height: pCtrl.side
        // handle delegate 须自写定位（模板不注入）——官方双分支完整公式（含
        // padding）：水平 x 由 visualPosition（RTL 镜像）驱动、y 居中；垂直
        // y 由 visualPosition 驱动、x 居中。
        x: root.horizontal ? root.leftPadding + root.visualPosition * (root.availableWidth - width) : root.leftPadding + (root.availableWidth - width) / 2
        y: root.horizontal ? root.topPadding + (root.availableHeight - height) / 2 : root.topPadding + root.visualPosition * (root.availableHeight - height)

        delta: pCtrl.shrinkSize
        expanded: hoverer.hovered || root.pressed || latch.active

        // 值变化锁存（TimerLatch，上游脉冲→电平）：valueChanged 是瞬时
        // 事件——不经转换直接注入 expanded 只闪一帧。latch 把事件转成
        // 持续 expanded=true 窗口（interval = movementDuration×2 滑动窗口），
        // 与 hover/按下共同驱动 expanded（hovered || pressed || latch.active），
        // 避免改值瞬间收缩再展开的闪动。长保持归消费方：CrystalCursor
        // 内部另有下游防抖 latch（delay，短窗口通用），两层职责正交
        // （脉冲→电平 vs 电平→防抖），不重复。锁存内化于 handle——不暴露
        // 接口（宿主的"刚移动"感知经手柄展开反馈呈现，无需读锁存状态）。
        TimerLatch {
            id: latch
            interval: Style.movementDuration * 2
            Connections {
                target: root
                function onValueChanged() {
                    latch.trigger();
                }
            }
        }

        ColorMapper {
            id: colorMapper
            // 采样渐变不透明化：轨道渐变左端 0.75 透明背景色，手柄为实体
            // 不透明（同 RangeSlider——轨道半透明、前景不透明）
            ColorMapperStop {
                position: 0
                color: root.Style.buttonText
            }
            ColorMapperStop {
                position: 1
                color: root.Style.accent
            }
        }

        // color 不经绑定——手动更新（colorAt 为 C++ 方法、QML 绑定不追踪
        // 方法体内 stops 访问，直接绑定会冻结在初始未就绪的采样）。源色
        // 来自 Style（统一样式接口）：Connections 监听 Style.valueChanged
        // （key = accent/buttonText）捕获附着传播变化触发重采样。
        Connections {
            target: root.Style
            function onValueChanged(group, key) {
                if (key === "accent" || key === "buttonText")
                    cursor.updateColor();
            }
        }

        function updateColor() {
            cursor.color = colorMapper.colorAt(root.position);
        }

        // 仅 hover/光标反馈：NoButton 不拦截按压（模板拖动在手柄上仍
        // 有效）；disabled 时无反馈
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: root.enabled
            cursorShape: root.horizontal ? Qt.SizeHorCursor : Qt.SizeVerCursor
        }

        HoverHandler {
            id: hoverer
            enabled: root.enabled
        }

        // —— 采样更新时机：handle 完成（stops 已就绪）刷新一次 + position
        // 变化（拖动/键盘/程序化）重采样；源色（Style.accent/buttonText）
        // 变化经 cursor 内哨兵只读属性捕获（见上）。colorAt 为 C++ 方法、
        // QML 绑定不追踪方法体内 stops 访问——初始未就绪会冻结黑（真实缺陷
        // 场景），故全部手动驱动。
        Component.onCompleted: {
            cursor.updateColor();
            root.positionChanged.connect(cursor.updateColor);
        }
    } //handle
}
