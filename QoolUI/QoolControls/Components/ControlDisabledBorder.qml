import QtQuick
import Qool

OctagonShape {
    id: root

    property bool animationEnabled: parent?.animationEnabled
                                    ?? Qore.animationEnabled

    QtObject {
        id: pCtrl
        property BasicControlFrame controlFrame: parent
    }

    Binding {
        when: pCtrl.controlFrame
        root.settings.cutSizes: pCtrl.controlFrame.backgroundSettings.cutSizes
        root.settings.borderWidth: pCtrl.controlFrame.backgroundSettings.borderWidth
        root.settings.fillColor: "transparent"
        root.settings.borderColor: Qore.style.negative
    }

    z: 30

    opacity: (root.parent?.enabled ?? false) ? 0 : 1
    BasicNumberBehavior on opacity {
        enabled: root.animationEnabled
    }
}
