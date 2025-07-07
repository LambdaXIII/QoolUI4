import QtQuick
import Qool

Behavior {
    property alias duration: ani.duration
    property alias easing: ani.easing
    readonly property bool runnint: ani.running

    enabled: targetProperty.object?.Style.animationEnabled ?? Style.animationEnabled

    NumberAnimation {
        id: ani
        duration: Style.transitionDuration
        easing.type: Easing.InOutQuad
    }
}
