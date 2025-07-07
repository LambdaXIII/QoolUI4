import QtQuick
import Qool.Controls.Components

BasicControlFrame {
    id: root

    property bool animationEnabled: (parent?.animationEnabled
                                     ?? Qore.animationEnabled)
                                    && Component.completed

    property color disabledColor: Style.negative
    ControlLockedCover {
        color: disabledColor
    }

    // BasicColorBehavior on backgroundColor {}
    // BasicColorBehavior on borderColor {}
    // BasicColorBehavior on disabledColor {}
}
