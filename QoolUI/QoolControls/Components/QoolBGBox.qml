import QtQuick
import Qool

/*!
    \qmltype QoolBGBox
    \inqmlmodule Qool.Controls.Components
    \brief 带可选标题标签的 QoolUI 背景盒，供控件 background 使用。

    \c title 经默认 \c label（BasicControlTitleText）渲染于盒体顶部；
    外部可整体替换 \c label 为任意 Item。\c settings（QoolBoxSettings）
    决定边框、填充与切角等外观。

    \section2 space 语义与空安全
    只读的 \c topSpace/\c leftSpace/\c rightSpace/\c bottomSpace 描述
    控件内容应让出的内边距，供宿主组合 padding：
    \list
    \li \c topSpace = 标签高度 + 边框宽度（有可见标签时），否则仅为边框宽度；
    \li \c left/\c rightSpace：有可见标签时收紧为边框宽度，
        否则使用 \c control.leftSpace/\c control.rightSpace；
    \li \c bottomSpace：有可见标签时使用 \c control.bottomSpace，否则为 0。
    \endlist
    全部经 \c label?.visible 空安全判断——未设置 \c label 时为 undefined，
    一律视为无标签。标签按 \c Binding 挂入顶部预留区（dummyTitle），
    宽度不超过可用宽度并右对齐。
*/

QoolBox {
    id: root

    property string title

    // 属性对象须显式挂 parent（QML 属性对象不自动成为声明对象的子项）：
    // 无 parent 时 effective 可见性恒 false（visible 是 effective 语义），
    // 标签可见性逻辑全部失效（2026-08-14 测试实证修复）。
    property Item label: BasicControlTitleText {
        parent: root
        text: root.title
        visible: text !== ""
        color: root.settings.borderColor
    }

    settings: QoolBoxSettings {
        borderWidth: Style.controlBorderWidth
        borderColor: Style.controlBorderColor
        fillColor: Style.controlBackgroundColor
        cutSizeTL: Style.controlCutSize
    }

    Item {
        id: dummyTitle
        x: root.settings.borderWidth + root.control.leftSpace
        y: root.settings.borderWidth
        width: root.width - root.settings.borderWidth * 2
               - root.control.leftSpace - root.control.rightSpace
        implicitHeight: root.control.topSpace - root.settings.borderWidth
    }

    Binding {
        when: root.label && root.label.visible
        root.label.parent: dummyTitle
        root.label.width: Math.min(dummyTitle.width, root.label.implicitWidth)
        root.label.y: 0
        root.label.x: dummyTitle.width - root.label.width
        dummyTitle.height: root.label.height
    }

    readonly property real topSpace: {
        let t = root.label?.visible ? root.label.height : 0
        return t + root.settings.borderWidth
    }
    readonly property real leftSpace: {
        let left = root.label?.visible ? 0 : root.control.leftSpace
        return left + root.settings.borderWidth
    }
    readonly property real rightSpace: {
        let right = root.label?.visible ? 0 : root.control.rightSpace
        return right + root.settings.borderWidth
    }

    readonly property real bottomSpace: {
        let b = root.label?.visible ? root.control.bottomSpace : 0
        return b + root.settings.borderWidth
    }

    implicitHeight: root.settings.borderWidth * 2 + root.control.topSpace + root.control.bottomSpace
    implicitWidth: root.settings.borderWidth * 2 + root.control.leftSpace
                   + root.control.rightSpace + root.label?.implicitWidth ?? 0
}
