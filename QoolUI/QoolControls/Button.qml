import QtQuick
import QtQuick.Templates as T
import Qool.Controls.Components
import Qool

/*!
    \qmltype Button
    \inqmlmodule Qool.Controls
    \brief 基于 T.AbstractButton 的 QoolUI 风格按钮。

    \c backgroundSettings（QoolBoxSettings）统一控制背景填充、边框与四角
    切角；\c highlighted 为只读便捷状态（\c enabled 且 \c hovered），
    驱动高亮覆盖层显示；\c checked 时背景切换为主题高亮色、文字与边框
    切换为高亮文字色。

    \section2 flat 属性（刻意设计）
    \c flat 为 \c true 时按钮背景完全透明（frameOpacity 置 0，无
    边框无填充），只保留文字与交互反馈层（pressed/hovered 高亮覆盖）。
    与 Qt Quick Controls 的 flat（去掉主题背景、保留文字悬浮反馈）
    语义一致，但与 QoolButton（保留描边）的行为差异是刻意的：
    \c flat 是"彻底无背景"模式，用于工具栏、导航栏等嵌入场景。
*/

T.AbstractButton {
    id: root

    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        cutSizeTL: root.Style.buttonCutSize
        cutSizeTR: root.Style.buttonCutSize
        cutSizeBL: root.Style.buttonCutSize
        cutSizeBR: root.Style.buttonCutSize
        fillColor: root.Style.button
        borderColor: root.Style.controlBorderColor
        borderWidth: root.Style.controlBorderWidth
        curved: true
    }

    property bool highlighted: enabled && hovered
    property bool flat: false

    font.pixelSize: root.Style.controlTextSize
    hoverEnabled: true

    SmartObject {
        id: pCtrl
        property real topSpace: Math.max(root.backgroundSettings.cutSizeTL,
                                         root.backgroundSettings.cutSizeTR)
        property real bottomSpace: Math.max(root.backgroundSettings.cutSizeBL,
                                            root.backgroundSettings.cutSizeBR)
        property real leftSpace: Math.max(root.backgroundSettings.cutSizeTL,
                                          root.backgroundSettings.cutSizeBL)
        property real rightSpace: Math.max(root.backgroundSettings.cutSizeTR,
                                           root.backgroundSettings.cutSizeBR)

        property real frameOpacity: root.flat ? 0 : 1

        BasicNumberBehavior on frameOpacity {
            enabled: root.Style.animationEnabled
        }

        Binding {
            when: pCtrl.frameOpacity < 1
            target: root.background
            property: "opacity"
            value: pCtrl.frameOpacity
        }
    }

    contentItem: BasicButtonText {
        id: mainText
        text: root.text
        font: root.font
        color: root.checked ? root.Style.highlightedText : root.Style.buttonText
    }

    leftPadding: root.backgroundSettings.borderWidth + pCtrl.leftSpace / 2
    rightPadding: root.backgroundSettings.borderWidth + pCtrl.rightSpace / 2
    topPadding: root.backgroundSettings.borderWidth + pCtrl.topSpace / 2
    bottomPadding: root.backgroundSettings.borderWidth + pCtrl.bottomSpace / 2

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding

    background: Rectangle {
        id: bgBox
        topLeftRadius: root.backgroundSettings.cutSizeTL
        topRightRadius: root.backgroundSettings.cutSizeTR
        bottomLeftRadius: root.backgroundSettings.cutSizeBL
        bottomRightRadius: root.backgroundSettings.cutSizeBR
        color: root.checked ? root.Style.highlight : root.backgroundSettings.fillColor
        border.width: root.backgroundSettings.borderWidth
        border.color: root.checked ? root.Style.highlightedText : root.backgroundSettings.borderColor
    }

    ControlPressedCover {
        visible: root.down
        highColor: root.Style.highlight
        lowColor: root.Style.highlightedText
        settings: root.backgroundSettings
    }

    ControlHighlightCover {
        highColor: root.Style.highlight
        lowColor: root.Style.highlightedText
        opacity: root.highlighted ? 1 : 0
        settings: root.backgroundSettings
    }

    ControlLockedCover {
        color: root.Style.negative
        settings: root.backgroundSettings
    }
}
