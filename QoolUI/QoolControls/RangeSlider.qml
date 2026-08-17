// Qool.Controls.RangeSlider：基于 HalfCrystal 的区间滑块（T.RangeSlider
// 模板 API 兼容）——三角形手柄平边相对、夹住已选段。
//
// 完整契约（几何/反馈/属性）见 docs/reference/Qool.Controls/RangeSlider.md。

import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import Qool

T.RangeSlider {
    id: root
    // 已选段填充色（与 second 手柄色），默认 Style.accent。
    property color color: root.Style.accent
    // "值刚被写入过"的声明式锁存窗口（500ms，滑动窗口——持续变化持续保持）。
    property bool justMoved: movementLatch.active
    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    // 常态高度：水晶轨道与手柄的常态（收缩）高度——展开时手柄占满控件全高（root.height）。
    readonly property real preferredHeight: root.height - Qore.bound(3, root.height * 0.25, 25)

    // 尺寸：反向排版策略（Slider 同款）——模板不自带 implicit 公式，root 直接
    // 给默认尺寸（80 × 25），background 基于 root 布局
    implicitWidth: 80
    implicitHeight: 25

    // —— 逻辑件：程序化变更锁存（TimerLatch——双值触发；Slider 的 NumberNotifier
    // 挂单一 value 无对应载体，justMoved 窗口由每次 valueChanged 滑动保持）——
    TimerLatch {
        id: movementLatch
        interval: 500
        Connections {
            target: root.first
            function onValueChanged() {
                movementLatch.trigger();
            }
        }
        Connections {
            target: root.second
            function onValueChanged() {
                movementLatch.trigger();
            }
        }
    }

    // —— 手柄中心线（已选段端面基准；行程语义与 Slider 一致：中心行程
    // [h/2, availW-h/2]——v=0/1 时手柄尖角贴轨道端）——
    readonly property real firstCenterX: root.leftPadding + root.first.visualPosition * (root.availableWidth - root.height) + root.height / 2
    readonly property real secondCenterX: root.leftPadding + root.second.visualPosition * (root.availableWidth - root.height) + root.height / 2

    // —— 轨道层（Item 容器——background 自动 fill 控件，内部坐标 = root 本地）：
    // 基底六边形（Crystal，text 色）+ 已选段（平切矩形——两端 = 手柄平边）——
    background: Item {
        // 基底轨道：六边形模型（与手柄同族 45° 斜边——Crystal 即
        // cut = shortEdge/2 特化）；恒为常态高度 + 垂直居中（三心对齐——
        // 水晶中心 = 轨道中心 = 控件中心）
        Crystal {
            id: track
            width: root.width
            height: root.preferredHeight
            y: (root.height - height) / 2
            // 基底 = Style.text（Slider 渐变左端色）——本组件无渐变
            color: root.Style.text
        } //track

        // 已选段：平切矩形（直角端面 = 手柄平边——HalfCrystal 三角形态的
        // 平边即组件中线 = 手柄中心线）；宽度恒非负（模板保证 first.position
        // <= second.position）；值相等时宽 0 不可见（退化形态）
        Rectangle {
            id: selection
            objectName: "selection" // 供 QML 测试读取（组件内部对象零暴露原则的测试例外）
            x: root.firstCenterX
            y: (root.height - root.preferredHeight) / 2
            width: root.secondCenterX - root.firstCenterX
            height: root.preferredHeight
            color: root.color
        } //selection
    } //background

    // —— first 手柄（HalfCrystal 三角形 direction W：尖角朝左——指向 from 端，
    // 平边朝右 = 已选段左端面）——
    first.handle: Item {
        id: firstHandle
        objectName: "firstHandle" // 供 QML 测试读取（组件内部对象零暴露原则的测试例外）
        width: root.height
        height: width
        // handle delegate 须自写定位（模板不注入）——官方公式；组件左上行程
        // [0, availW-h]（展开态 h×h 时尖角 = 组件左缘贴轨道端；常态缩进
        // (h-pH)/2）
        x: root.leftPadding + root.first.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2

        HalfCrystal {
            id: firstCrystal
            objectName: "firstCrystal" // 供 QML 测试读取（几何契约是公开视觉行为）
            direction: Qore.W
            // 动画期间 CurveRenderer（原生 AA——展开缩放时小三角边缘平滑），
            // 静止回退默认 GeometryRenderer（Slider 同款折中）
            preferredRendererType: root.animationEnabled ? Shape.CurveRenderer : Shape.UnknownRenderer
            anchors.centerIn: parent
            // 仅 hover/光标反馈：NoButton 不拦截按压（模板拖动在手柄上仍有效）；
            // containmentMask 不设（hover 域宽松为刻意设计——Slider 同款）；
            // disabled 时无反馈
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                enabled: root.enabled
                cursorShape: Qt.SizeHorCursor
            }

            HoverHandler {
                id: firstHoverer
                enabled: root.enabled
            }

            // 展开态占满 handle 区域（= 控件高度，不超出边界）；常态 = 轨道
            // 高度（preferredHeight——平边与轨道/已选段端面同高贴合）；pressed
            // 取自模板（first.pressed——touch/mouse/keys 均计入）
            readonly property bool encountered: {
                return firstHoverer.hovered || root.first.pressed || root.justMoved;
            }

            width: height
            height: encountered ? root.height : root.preferredHeight
            BasicNumberBehavior on height {
                enabled: root.animationEnabled
                duration: Style.transitionDuration
            }
            // 段色采样：first 手柄在基底段（text 色）——与 Slider 渐变采样
            // 同语义的纯色特化；反馈仅展开
            color: root.Style.text
            // Behavior 须声明在本对象内（on 作用于声明者自己的属性）
        } //firstCrystal
    } //first.handle

    // —— second 手柄（HalfCrystal 三角形 direction E：尖角朝右——指向 to 端，
    // 平边朝左 = 已选段右端面）——
    second.handle: Item {
        id: secondHandle
        objectName: "secondHandle" // 供 QML 测试读取（组件内部对象零暴露原则的测试例外）
        width: root.height
        height: width
        x: root.leftPadding + root.second.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2

        HalfCrystal {
            id: secondCrystal
            objectName: "secondCrystal" // 供 QML 测试读取（几何契约是公开视觉行为）
            direction: Qore.E
            preferredRendererType: root.animationEnabled ? Shape.CurveRenderer : Shape.UnknownRenderer
            anchors.centerIn: parent
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                enabled: root.enabled
                cursorShape: Qt.SizeHorCursor
            }

            HoverHandler {
                id: secondHoverer
                enabled: root.enabled
            }

            readonly property bool encountered: {
                return secondHoverer.hovered || root.second.pressed || root.justMoved;
            }

            width: height
            height: encountered ? root.height : root.preferredHeight
            BasicNumberBehavior on height {
                enabled: root.animationEnabled
                duration: Style.transitionDuration
            }
            // 段色采样：second 手柄在已选段（color 色）
            color: root.color
        } //secondCrystal
    } //second.handle
}
