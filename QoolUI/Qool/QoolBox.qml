import QtQuick
import Qool

Item {
    id: root

    property OctagonSettings settings: OctagonSettings {
        cutSize: Style.controlCutSize
        borderWidth: Style.controlBorderWidth
        borderColor: Style.accent
        fillColor: Style.dark
    }
    property alias cutSize: root.settings.cutSize

    property Item fillItem: null

    readonly property alias shape: loader.item
    property OctagonShapeHelper control: OctagonShapeHelper {
        settings: root.settings
    }

    property bool round: false

    property bool animatingHint: false

    SmartObject {
        id: pCtrl

        Component {
            id: boxShape
            OctagonShape {}
        }

        Component {
            id: roundShape
            OctagonRoundedShape {}
        }

        Component {
            id: rectShape
            OctagonRectangleShape {}
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: {
            if (root.animatingHint == false) {
                let cond1 = !root.fillItem && root.round
                const half = Math.min(root.width, root.height) / 2
                let cond2 = root.settings.cutSizeTL <= half
                    && root.settings.cutSizeTR <= half
                    && root.settings.cutSizeBL <= half
                    && root.settings.cutSizeBR <= half
                let cond3 = root.settings.cutSizeTL === 0
                    && root.settings.cutSizeTR === 0
                    && root.settings.cutSizeBL === 0
                    && root.settings.cutSizeBR === 0
                if (cond1 && (cond2 || cond3))
                    return rectShape
            }
            return root.round ? roundShape : boxShape
        }
    }

    Binding {
        when: loader.item
        target: loader.item
        property: "settings"
        value: root.settings
    }

    Binding {
        when: loader.item
        target: loader.item
        property: "fillItem"
        value: root.fillItem
    }
    Binding {
        when: loader.item
        target: root
        property: "control"
        value: loader.item.control
    }
    containmentMask: loader.item
}
