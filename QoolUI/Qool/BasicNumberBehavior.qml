import QtQuick
import Qool

Behavior {
    property alias duration: ani.duration
    property alias easing: ani.easing
    readonly property bool runnint: ani.running

    enabled: targetProperty.object?.animationEnabled ?? Qore.animationEnabled

    NumberAnimation {
        id: ani
        duration: Qore.style.transitionDuration
        easing.type: Easing.InOutQuad
    }
}
