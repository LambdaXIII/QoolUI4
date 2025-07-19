import QtQuick
import Qool

Behavior {
    id: root

    property int duration: Style.transitionDuration
    property Item container: targetProperty.object

    enabled: container?.Style?.animationEnabled ?? Style.animationEnabled

    SequentialAnimation {
        id: ani
        NumberAnimation {
            target: root.container
            property: "opacity"
            to: 0
            duration: root.duration
            easing.type: Easing.InBounce
        }
        PropertyAction {}
        NumberAnimation {
            target: root.container
            property: "opacity"
            to: 1
            duration: root.duration
            easing.type: Easing.OutBounce
        }
    }
}
