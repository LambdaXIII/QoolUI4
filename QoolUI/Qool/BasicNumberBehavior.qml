import QtQuick
import Qool

Behavior {
    property alias duration: ani.duration
    property alias easing: ani.easing
    readonly property bool runnint: ani.running

    enabled: targetProperty.object?.animationEnabled ?? QoolConstants.animationEnabled

    NumberAnimation {
        id: ani
        duration: QoolConstants.tansitionDuration
        easing.type: Easing.InOutQuad
    }
}
