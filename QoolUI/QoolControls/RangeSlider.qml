// Qool.Controls.RangeSlider：基于 HalfCrystal 的区间滑块（v3 Color 滑块视觉族
// 的区间扩展）。
//
// 设计（用户指令 2026-08-16——基于 HalfCrystal、仿照 Slider；与 Slider 的区别：
// 轨道非渐变，Style.accent 填充已选区域）：
//   - 手柄 = HalfCrystal 三角形（first: direction W 尖朝左、second: direction E
//     尖朝右）——平边相对、夹住已选段（范围边界语义：尖角朝外指向各自未选
//     段方向）。HalfCrystal 三角形态占组件半宽（画布左/右半），平边 = 组件
//     中线 = 手柄中心线——已选段左右端面 = 手柄平边（平切矩形端面，天然对齐）。
//   - 轨道 = Crystal 六边形（同 Slider——OctagonShape 特化，cut = shortEdge/2），
//     基底色 Style.text（= Slider 渐变左端色）——**无渐变**：已选段 = 平切矩形
//     （Rectangle，色 = color 默认 Style.accent），两端贴手柄平边。
//   - 已选段几何：x = first 手柄中心线、右缘 = second 手柄中心线——width =
//     secondCenter - firstCenter >= 0 恒成立（模板保证 first.position <=
//     second.position，正/倒置范围均成立：pos = (value-from)/(to-from)，正序
//     first.value <= second.value、倒序差除以负——数学恒等，无需防御）。
//   - 手柄色 = 段色采样语义（Slider 渐变采样 → 纯色两段特化）：first =
//     Style.text（自身在基底段）、second = color（自身在已选段）——平边与
//     已选段端面同色贴合、轮廓靠 borderColor 描边（HalfCrystal 默认自动对比）。
//   - 展开反馈照 Slider 核心：hover/按下/刚移动（justMoved 锁存 500ms）→ 手柄
//     展开到控件全高（常态 = preferredHeight——Qore.bound(3, 高度×25%, 25)；
//     轨道恒常态高；三角形尖角常态缩进轨道内 (h-pH)/2、展开顶到轨道端
//     （v=0/1 时尖角 = 0/availW）——展开反馈位移比菱形更明显）。动画经
//     animationEnabled 链式门控（parent?.animationEnabled ?? Style.animationEnabled）。
//   - 锁存：TimerLatch + 双 Connections（first/second valueChanged）——任一值被
//     写入（无论谁写）→ 两手柄展开 500ms；不暴露 valueVelocity（Slider 的
//     NumberNotifier 挂在单一 value 上，RangeSlider 双值无单一载体——justMoved
//     窗口由每次 valueChanged 触发滑动，用户可见行为等价）。
//   - 交互 = 模板默认（点击跳转最近手柄、拖动连续、键盘步进活动手柄——官方
//     行为，接口兼容 QtQuick.Templates.RangeSlider）。
//   - 退化形态：first.value == second.value → 已选段宽 0（不可见）+ 两三角形
//     平边相对重合 = 视觉完整菱形（水晶语言自洽——W 左半 + E 右半无缝互补）。
//
// 公开属性：
//   - color：已选段填充色 + second 手柄色（默认 Style.accent）——宿主换色即换
//     已选区域视觉。
//   - animationEnabled：动画门控（父链继承，回退 Style.animationEnabled）。
//   - justMoved："值刚被写入过"的声明式锁存窗口（500ms）。
//   - preferredHeight：水晶轨道与手柄的常态高度（收缩态）——展开时手柄占满
//     控件全高。
//
// 注意（易误解）：
//   - first/second handle delegate 必须自写 x/y（T.RangeSlider 模板不注入定位——
//     官方惯例，Slider 同款）。
//   - 手柄展开态占满控件高度（不超出边界）——clip 与否不影响反馈。
//   - 手柄 MouseArea 仅做 hover/光标反馈（acceptedButtons: Qt.NoButton——不拦截
//     模板拖动）；不挂 containmentMask（HalfCrystal 掩码已精确、手柄仍刻意
//     不设——NoButton 仅光标反馈、hover 域宽松为刻意设计，Slider 同款）。

import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import Qool

/*!
    \qmltype RangeSlider
    \inqmlmodule Qool.Controls
    \brief 区间滑块：六边形轨道 + 水晶三角手柄，accent 填充已选区域（Slider
    的区间版）。

    \c first/\c second 两个手柄界定区间（模板属性，接口兼容
    QtQuick.Templates.RangeSlider——点击跳转最近手柄、拖动连续、键盘步进均为
    官方行为）。轨道为 \l {Qool::Crystal}{Crystal} 六边形
    （\c text 基底色，无渐变），\c first 与 \c second 之间的已选区域以
    \l color（默认 Style.accent）平切矩形填充；手柄为
    \l {Qool::HalfCrystal}{HalfCrystal} 三角形（first 尖朝左、second
    尖朝右——平边相对夹住已选段，尖角朝外指向各自未选段）。

    \section2 主题相关
    \list
    \li \l color 同时是已选段填充色与 second 手柄色——宿主换色即换已选区域
        视觉；轨道基底固定 Style.text。
    \li first 手柄色固定 Style.text（基底段色）、second 固定 \l color（已选段色）
        ——段色采样语义（Slider 渐变采样在纯色两段下的特化）。
    \endlist

    \section2 交互反馈
    \list
    \li 悬停/按下/刚移动（任一值变化后 500ms 锁存窗口）：对应手柄展开到控件
        全高（常态 = \l preferredHeight——收缩 \c{Qore.bound(3, 高度×0.25, 25)}；
        轨道与手柄常态同高、中心对齐；三角形尖角常态缩进轨道内、展开顶到
        轨道端），动画随 \l animationEnabled 门控；悬停时光标变水平双向箭头
        （仅 enabled）。
    \li 程序化写入 \c first.value/\c second.value（如外部绑定）：两个手柄均展开
        约 500ms（\l justMoved 锁存窗口——"值被写入即反馈"语义，无论谁写的）；
        持续变化期间窗口随每次值变化滑动不落。
    \li 倒置范围（from > to）：位置反向，已选段与手柄自动跟随。
    \endlist

    \section2 状态属性
    \list
    \li \c animationEnabled：动画开关——父链继承（宿主可在父级统一关闭），
        回退 \l Style 的 \c animationEnabled。
    \li \c justMoved："值刚被写入过"的声明式锁存窗口（500ms，滑动窗口）。
    \li \c preferredHeight：水晶轨道与手柄的常态高度（收缩态）——展开时手柄
        占满控件全高；宿主可用它参与外部布局计算。
    \endlist

    \note 首次同时设置两手柄值时注意官方 \c setValues() 契约：\c first.value 与
    \c second.value 之间存在循环依赖，组件完成前分别赋值可能被互相钳制——
    官方文档建议经 \c setValues() 一次性设置。
*/
T.RangeSlider {
    id: root
    /*! \qmlproperty color 已选段填充色（与 second 手柄色），默认 Style.accent。 */
    property color color: root.Style.accent
    /*! \qmlproperty bool "值刚被写入过"的声明式锁存窗口（500ms，滑动窗口——持续变化持续保持）。 */
    property bool justMoved: movementLatch.active
    /*! \qmlproperty bool 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。 */
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    /*! \qmlproperty real 常态高度：水晶轨道与手柄的常态（收缩）高度——展开时手柄占满控件全高（root.height）。 */
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
        // <= second.position——见文件头数学）；值相等时宽 0 不可见（退化形态）
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
        // (h-pH)/2——见文件头）
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
            // 段色采样：first 手柄在基底段（text 色）——与 Slider 渐变采样同
            // 语义的纯色特化；反馈仅展开（v3 提亮已裁定取消）
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
