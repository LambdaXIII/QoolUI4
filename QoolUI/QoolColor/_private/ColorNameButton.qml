// NOTE(迁移) v3 Qool.Color/_private/ColorNameButton.qml 拍平重写。
// 拍平内容（v3 → 本文件内联）：
//   - AbstractButton（QtQuick.Controls）→ T.AbstractButton（QtQuick.Templates）
//     ——v4 模块惯例（CycleChoice 同款），不再依赖 QtQuick.Controls。
//   - AnimatedBar_AlignHCenter（Qool.Controls.Basic）→ 内联指示条
//     （clip + 居中圆角条，width = 进度 × 父宽）。
//   - ButtonGroup.group 互斥 → group 属性拍平（独占组语义内联）：
//     点选未选中项 → 选中并取消组内旧项；点击已选中项 → 保持选中
//     （v3 exclusive 组"用户不可点击取消"行为）；程序化取消（deselect）
//     经 checked=false 清空组引用。
// Style 对位：textColor→text、highlightColor→highlight、
//   foregroundColor→text（T08 对照表）、recommendedForegroundColor→
//   ThemeDB.recommendForeground、controlTransitionDuration→transitionDuration、
//   PixelFont.normalFont→PixelFont.normal。
// 与 v3 的刻意差异：无（行为逐字；Style/依赖对位见上）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color

/*!
    \qmltype ColorNameButton
    \inqmlmodule Qool.Color
    \brief 色名行按钮（v3 ColorNameButton 拍平）：色名 + 色块 + 选中展开。

    显示色名（\l name）与对应色块（\l color，经
    \l {ColorDB}{ColorDB.color(name)} 解析）。选中时色块展开铺满整行、
    文字反色为前景对比色（\l {ThemeDB}{ThemeDB.recommendForeground}），
    底部悬停指示条渐显。

    \section1 互斥选择（易误解，特别说明）

    \c group 属性是对 v3 \c ButtonGroup.group 的拍平（独占组语义内联）：
    \list
    \li 点击未选中项 → 本项选中，组内原选中项自动取消。
    \li \b 点击已选中项 → 保持选中，不会取消（v3 exclusive 组行为，
        用户不可点击取消；取消只能程序化置 \c checked = false）。
    \li \c group 为 null（独立使用）→ 退化为普通切换按钮（点选切换）。
    \endlist
    组引用由宿主（\l ColorNameView）注入；组对象的 \c checkedButton
    属性由本组件在切换时维护。

    \section1 属性

    \qmlproperty string ColorNameButton::name
    色名，默认 "white"。\l color 由 \l {ColorDB}{ColorDB.color(name)}
    解析（未知名回退默认白）。

    \qmlproperty color ColorNameButton::color
    只读，\l name 对应的颜色（ColorDB 解析结果）。

    \qmlproperty var ColorNameButton::group
    互斥组引用（v3 ButtonGroup 拍平，见上）。null 时点选为普通切换。

    \qmlproperty bool ColorNameButton::animationEnabled
    动画总开关，默认继承父级或 \l {Style}{Style.animationEnabled}
    （v4 惯例）。
*/
T.AbstractButton {
    id: root

    // 专项注释（缺陷修复）：v3 根为 Qool.Controls.AbstractButton（implicit 自动
    // 取自 contentItem）；拍平件改根为 T.AbstractButton 后实测（Qt 6.11）
    // Templates 不传播 contentItem implicit——implicit 恒 0。显式绑定回传。
    implicitWidth: contentItem.implicitWidth
    implicitHeight: contentItem.implicitHeight

    // 动画总开关：v3 同款传播（父级属性 → Style）。
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Style.animationEnabled

    property string name: "white"
    readonly property color color: ColorDB.color(root.name)

    // 互斥组（v3 ButtonGroup.group 拍平）：由 ColorNameView 注入。
    // 类型用 var（而非 QtObject）：组的 checkedButton 是动态属性，
    // QtObject 静态类型会让 qmllint 报 missing-property。
    property var group: null

    font: PixelFont.normal
    hoverEnabled: true

    QtObject {
        id: pControl
        property real spacing: 6
    } //pControl

    contentItem: Item {
        id: mainItem
        implicitHeight: nameText.implicitHeight
        implicitWidth: nameText.implicitWidth

        Text {
            id: nameText
            anchors.fill: parent
            text: root.name
            font: root.font
            color: root.Style.text
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft

            leftPadding: implicitHeight + pControl.spacing
            rightPadding: pControl.spacing
        } //nameText

        Rectangle {
            id: box
            z: -10
            width: height
            height: parent.height
            border.width: 1
            border.color: ThemeDB.recommendForeground(root.color)
            color: root.color
        } //box
    } //mainItem

    topPadding: 2
    bottomPadding: 2 + indicator.height

    // 悬停指示条（v3 AnimatedBar_AlignHCenter 内联）。
    Item {
        id: indicator
        clip: true
        implicitHeight: 4
        implicitWidth: 10

        property color color: root.down ? root.Style.highlight
                                        : root.Style.text
        property real progress: root.hovered ? 1 : 0

        width: root.contentItem.width
        height: 2
        y: root.contentItem.y + root.contentItem.height + 2

        Rectangle {
            color: indicator.color
            border.width: 0
            radius: height / 2
            x: (indicator.width - width) / 2
            height: indicator.height
            width: indicator.width * indicator.progress
        } //bar

        BasicColorBehavior on color {
            enabled: root.Style.animationEnabled
        }
        BasicNumberBehavior on progress {
            enabled: root.Style.animationEnabled
        }
    } //indicator

    states: [
        State {
            when: root.checked
            PropertyChanges {
                box.width: mainItem.width
                nameText.leftPadding: pControl.spacing
                nameText.color: ThemeDB.recommendForeground(root.color)
            }
        }
    ] //states

    transitions: [
        Transition {
            enabled: root.animationEnabled
            NumberAnimation {
                property: "width"
                duration: root.Style.transitionDuration
                easing.type: Easing.InOutQuart
            }

            NumberAnimation {
                property: "leftPadding"
                duration: root.Style.transitionDuration
                easing.type: Easing.InOutQuart
            }

            ColorAnimation {
                duration: root.Style.transitionDuration
                easing.type: Easing.InOutQuart
            }
        }
    ] //transitions

    // ===== 互斥选择（v3 ButtonGroup exclusive 语义拍平）=====
    // 独占互斥是刻意设计的 UI 模式（v3 ButtonGroup exclusive 语义），
    // 覆盖全部 checked 变化路径（点击与程序化写入）——防后人当冗余简化。

    onClicked: {
        if (root.group) {
            // 独占组：点击已选中项保持选中（checked 已为 true，无变化即无操作）。
            // 互斥逻辑由 onCheckedChanged 统一承担。
            root.checked = true
        } else {
            root.checked = !root.checked
        }
    } //onClicked

    onCheckedChanged: {
        if (!root.group)
            return
        if (root.checked) {
            // 程序化选中同样走独占互斥（v3 ButtonGroup 对任意 checked 变化
            // 自动互斥）：先取消旧选中，再更新组引用。
            if (root.group.checkedButton && root.group.checkedButton !== root)
                root.group.checkedButton.checked = false
            root.group.checkedButton = root
        } else if (root.group.checkedButton === root) {
            // 程序化取消（deselect）/组内被替换：同步组引用。
            root.group.checkedButton = null
        }
    } //onCheckedChanged
}
