import QtQuick
import Qool

Palette {
    id: root
    property string theme: "system"
    Style.theme: root.theme

    active {
        accent: root.Style.active.accent
        alternateBase: root.Style.active.alternateBase
        base: root.Style.active.base
        brightText: root.Style.active.brightText
        button: root.Style.active.button
        buttonText: root.Style.active.buttonText
        dark: root.Style.active.dark
        highlight: root.Style.active.highlight
        highlightedText: root.Style.active.highlightedText
        light: root.Style.active.light
        link: root.Style.active.link
        linkVisited: root.Style.active.linkVisited
        mid: root.Style.active.mid
        midlight: root.Style.active.midlight
        placeholderText: root.Style.active.placeholderText
        shadow: root.Style.active.shadow
        text: root.Style.active.text
        toolTipBase: root.Style.active.toolTipBase
        toolTipText: root.Style.active.toolTipText
        window: root.Style.active.window
        windowText: root.Style.active.windowText
    }

    inactive {
        accent: root.Style.inactive.accent
        alternateBase: root.Style.inactive.alternateBase
        base: root.Style.inactive.base
        brightText: root.Style.inactive.brightText
        button: root.Style.inactive.button
        buttonText: root.Style.inactive.buttonText
        dark: root.Style.inactive.dark
        highlight: root.Style.inactive.highlight
        highlightedText: root.Style.inactive.highlightedText
        light: root.Style.inactive.light
        link: root.Style.inactive.link
        linkVisited: root.Style.inactive.linkVisited
        mid: root.Style.inactive.mid
        midlight: root.Style.inactive.midlight
        placeholderText: root.Style.inactive.placeholderText
        shadow: root.Style.inactive.shadow
        text: root.Style.inactive.text
        toolTipBase: root.Style.inactive.toolTipBase
        toolTipText: root.Style.inactive.toolTipText
        window: root.Style.inactive.window
        windowText: root.Style.inactive.windowText
    }
    disabled {
        accent: root.Style.disabled.accent
        alternateBase: root.Style.disabled.alternateBase
        base: root.Style.disabled.base
        brightText: root.Style.disabled.brightText
        button: root.Style.disabled.button
        buttonText: root.Style.disabled.buttonText
        dark: root.Style.disabled.dark
        highlight: root.Style.disabled.highlight
        highlightedText: root.Style.disabled.highlightedText
        light: root.Style.disabled.light
        link: root.Style.disabled.link
        linkVisited: root.Style.disabled.linkVisited
        mid: root.Style.disabled.mid
        midlight: root.Style.disabled.midlight
        placeholderText: root.Style.disabled.placeholderText
        shadow: root.Style.disabled.shadow
        text: root.Style.disabled.text
        toolTipBase: root.Style.disabled.toolTipBase
        toolTipText: root.Style.disabled.toolTipText
        window: root.Style.disabled.window
        windowText: root.Style.disabled.windowText
    }
}
