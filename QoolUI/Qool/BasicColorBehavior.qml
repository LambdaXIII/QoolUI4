import QtQuick
import Qool

Behavior {
    id: root
    property alias duration: ani.duration
    property alias easing: ani.easing
    readonly property bool running: ani.running

    enabled: targetProperty.object?.animationEnabled ?? QoolConstants.animationEnabled

    ColorAnimation {
        id: ani
        duration: QoolConstants.transitionDuration
        easing.type: Easing.InOutQuad
    }
}
