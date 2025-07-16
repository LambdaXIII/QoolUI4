import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Controls.Components

T.ToolButton {
    id: root

    readonly property bool isFirst: Positioner.isFirstItem

    property OctagonSettings backgroundSettings: OctagonSettings {
        fillColor: root.Style.button
        borderWidth: root.Style.controlBorderWidth
        borderColor: root.Style.controlBorderColor
        cutSizeTL: root.isFirst ? 5 : 0
    }

    font.pixelSize: root.Style.controlTextSize

    contentItem: Text {
        id: mainText
        text: root.text
        font: root.font
        color: root.Style.buttonText
        leftPadding: root.backgroundSettings.cutSizeTL
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding

    padding: 2

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
        highColor: root.Style.highlight
        lowColor: root.Style.highlightedText
        opacity: root.hovered ? 1 : 0
        settings: root.backgroundSettings
    }

    ControlLockedCover {
        color: root.Style.negative
        settings: root.backgroundSettings
    }

    Binding {
        when: root.checked
        root.backgroundSettings.fillColor: root.Style.highlight
        root.backgroundSettings.borderColor: root.Style.highlightedText
        mainText.color: root.Style.highlightedText
    }
}
