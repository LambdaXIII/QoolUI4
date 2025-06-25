import QtQuick
import Qool

Palette {
    id: root

    active {
        accent: Style.accent
        alternateBase: Style.alternateBase
        base: Style.base
        brightText: Style.brightText
        button: Style.button
        buttonText: Style.buttonText
        dark: Style.dark
        highlight: Style.highlight
        highlightedText: Style.highlightedText
        light: Style.light
        link: Style.link
        linkVisited: Style.linkVisited
        mid: Style.mid
        midlight: Style.midlight
        placeholderText: Style.placeholderText
        shadow: Style.shadow
        text: Style.text
        toolTipBase: Style.toolTipBase
        toolTipText: Style.toolTipText
        window: Style.window
        windowText: Style.windowText
    }

    disabled {
        accent: Style.disabled
        alternateBase: Style.alternateBase
        base: Style.disabled
        brightText: Style.brightText
        button: Style.disabled
        buttonText: Style.disabledText
        dark: Style.dark
        highlight: Style.highlight
        highlightedText: Style.highlightedText
        light: Style.light
        link: Style.link
        linkVisited: Style.linkVisited
        mid: Style.mid
        midlight: Style.midlight
        placeholderText: Style.placeholderText
        shadow: Style.shadow
        text: Style.disabledText
        toolTipBase: Style.toolTipBase
        toolTipText: Style.toolTipText
        window: Style.window
        windowText: Style.disabledText
    }
}
