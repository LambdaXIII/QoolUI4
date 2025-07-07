import QtQuick
import Qool

Palette {
    id: root
    property string theme: "system"
    Style.theme: root.theme

    Component.onCompleted: console.log(Style.theme)

    active {
        accent: Style.active.accent
        alternateBase: Style.active.alternateBase
        base: Style.active.base
        brightText: Style.active.brightText
        button: Style.active.button
        buttonText: Style.active.buttonText
        dark: Style.active.dark
        highlight: Style.active.highlight
        highlightedText: Style.active.highlightedText
        light: Style.active.light
        link: Style.active.link
        linkVisited: Style.active.linkVisited
        mid: Style.active.mid
        midlight: Style.active.midlight
        placeholderText: Style.active.placeholderText
        shadow: Style.active.shadow
        text: Style.active.text
        toolTipBase: Style.active.toolTipBase
        toolTipText: Style.active.toolTipText
        window: Style.active.window
        windowText: Style.active.windowText
    }

    inactive {
        accent: Style.inactive.accent
        alternateBase: Style.inactive.alternateBase
        base: Style.inactive.base
        brightText: Style.inactive.brightText
        button: Style.inactive.button
        buttonText: Style.inactive.buttonText
        dark: Style.inactive.dark
        highlight: Style.inactive.highlight
        highlightedText: Style.inactive.highlightedText
        light: Style.inactive.light
        link: Style.inactive.link
        linkVisited: Style.inactive.linkVisited
        mid: Style.inactive.mid
        midlight: Style.inactive.midlight
        placeholderText: Style.inactive.placeholderText
        shadow: Style.inactive.shadow
        text: Style.inactive.text
        toolTipBase: Style.inactive.toolTipBase
        toolTipText: Style.inactive.toolTipText
        window: Style.inactive.window
        windowText: Style.inactive.windowText
    }
    disabled {
        accent: Style.disabled.accent
        alternateBase: Style.disabled.alternateBase
        base: Style.disabled.base
        brightText: Style.disabled.brightText
        button: Style.disabled.button
        buttonText: Style.disabled.buttonText
        dark: Style.disabled.dark
        highlight: Style.disabled.highlight
        highlightedText: Style.disabled.highlightedText
        light: Style.disabled.light
        link: Style.disabled.link
        linkVisited: Style.disabled.linkVisited
        mid: Style.disabled.mid
        midlight: Style.disabled.midlight
        placeholderText: Style.disabled.placeholderText
        shadow: Style.disabled.shadow
        text: Style.disabled.text
        toolTipBase: Style.disabled.toolTipBase
        toolTipText: Style.disabled.toolTipText
        window: Style.disabled.window
        windowText: Style.disabled.windowText
    }
}
