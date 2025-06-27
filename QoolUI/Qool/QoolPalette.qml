import QtQuick
import Qool

Palette {
    id: root
    property string theme: Qore.style.theme
    property Style style: Style {
        theme: root.theme
    }

    active {
        accent: style.active.accent
        alternateBase: style.active.alternateBase
        base: style.active.base
        brightText: style.active.brightText
        button: style.active.button
        buttonText: style.active.buttonText
        dark: style.active.dark
        highlight: style.active.highlight
        highlightedText: style.active.highlightedText
        light: style.active.light
        link: style.active.link
        linkVisited: style.active.linkVisited
        mid: style.active.mid
        midlight: style.active.midlight
        placeholderText: style.active.placeholderText
        shadow: style.active.shadow
        text: style.active.text
        toolTipBase: style.active.toolTipBase
        toolTipText: style.active.toolTipText
        window: style.active.window
        windowText: style.active.windowText
    }

    inactive {
        accent: style.inactive.accent
        alternateBase: style.inactive.alternateBase
        base: style.inactive.base
        brightText: style.inactive.brightText
        button: style.inactive.button
        buttonText: style.inactive.buttonText
        dark: style.inactive.dark
        highlight: style.inactive.highlight
        highlightedText: style.inactive.highlightedText
        light: style.inactive.light
        link: style.inactive.link
        linkVisited: style.inactive.linkVisited
        mid: style.inactive.mid
        midlight: style.inactive.midlight
        placeholderText: style.inactive.placeholderText
        shadow: style.inactive.shadow
        text: style.inactive.text
        toolTipBase: style.inactive.toolTipBase
        toolTipText: style.inactive.toolTipText
        window: style.inactive.window
        windowText: style.inactive.windowText
    }
    disabled {
        accent: style.disabled.accent
        alternateBase: style.disabled.alternateBase
        base: style.disabled.base
        brightText: style.disabled.brightText
        button: style.disabled.button
        buttonText: style.disabled.buttonText
        dark: style.disabled.dark
        highlight: style.disabled.highlight
        highlightedText: style.disabled.highlightedText
        light: style.disabled.light
        link: style.disabled.link
        linkVisited: style.disabled.linkVisited
        mid: style.disabled.mid
        midlight: style.disabled.midlight
        placeholderText: style.disabled.placeholderText
        shadow: style.disabled.shadow
        text: style.disabled.text
        toolTipBase: style.disabled.toolTipBase
        toolTipText: style.disabled.toolTipText
        window: style.disabled.window
        windowText: style.disabled.windowText
    }
}
