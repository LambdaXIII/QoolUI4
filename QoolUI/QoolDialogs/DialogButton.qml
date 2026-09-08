import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Controls.Components

// DialogButton：对话域语义按钮（契约见参考文档与 ADR-0022 KD2）。
// role → 语义色映射是全文件唯一的色决策面：fill/border/foreground 三个
// helper 派生自 dlgRole，背景与文字都引用它们。皮肤手法照 QoolControls 的
// ToolButton（单文件皮肤），裁剪项：无 checked 视觉、无切角联动。
T.AbstractButton {
    id: root

    property bool highlighted: false

    // attached 必须用 T. 限定名：裸名 DialogButtonBox 解析到本模块同名复合件
    readonly property int dlgRole: T.DialogButtonBox.buttonRole

    readonly property bool semanticRole: dlgRole === T.DialogButtonBox.AcceptRole
                                         || dlgRole === T.DialogButtonBox.YesRole
                                         || dlgRole === T.DialogButtonBox.DestructiveRole
    readonly property color fillColor: semanticRole
                                       ? (dlgRole === T.DialogButtonBox.DestructiveRole
                                          ? root.Style.negative : root.Style.positive)
                                       : root.Style.button
    readonly property color borderColor: semanticRole
                                         ? (dlgRole === T.DialogButtonBox.DestructiveRole
                                            ? root.Style.negative : root.Style.positive)
                                         : root.Style.controlBorderColor
    readonly property color foregroundColor: semanticRole
                                             ? ThemeHQ.recommendForeground(fillColor)
                                             : root.Style.buttonText

    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        fillColor: root.fillColor
        borderWidth: root.Style.controlBorderWidth
        borderColor: root.borderColor
    }

    font.pixelSize: root.Style.controlTextSize

    contentItem: Text {
        id: mainText
        text: root.text
        font: root.font
        color: root.foregroundColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    topPadding: 2
    bottomPadding: 2
    leftPadding: 4
    rightPadding: 4

    background: QoolBox {
        settings: root.backgroundSettings
    }

    ControlPressedCover {
        visible: root.down
        highColor: root.Style.highlight
        lowColor: root.Style.highlightedText
        settings: root.backgroundSettings
    }

    ControlHighlightCover {
        objectName: "highlightCover"
        highColor: root.Style.highlight
        lowColor: root.Style.highlightedText
        opacity: (root.highlighted || root.hovered) ? 1 : 0
    }

    ControlLockedCover {
        color: root.Style.negative
        settings: root.backgroundSettings
    }

    implicitWidth: {
        const w1 = leftInset + implicitBackgroundWidth + rightInset;
        const w2 = leftPadding + implicitContentWidth + rightPadding;
        return Math.max(w1, w2);
    }

    implicitHeight: {
        const h1 = topInset + implicitBackgroundHeight + bottomInset;
        const h2 = topPadding + implicitContentHeight + bottomPadding;
        return Math.max(h1, h2);
    }
}
