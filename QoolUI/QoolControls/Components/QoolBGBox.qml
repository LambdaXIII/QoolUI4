import QtQuick
import Qool

// 带可选标题标签的 QoolUI 背景盒（供控件 background 使用）：title 经默认
// label 渲染于盒体顶部，可整体替换 label 为任意 Item；settings 决定外观。
// space 语义与空安全判断见 docs/reference/Qool.Controls/QoolBGBox.md。

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
