import QtQuick
import Qool.Controls.Components

BasicControlFrame {
    id: root

    property color disabledColor: Style.negative
    ControlLockedCover {
        color: disabledColor
    }

    // BasicColorBehavior on backgroundColor {}
    // BasicColorBehavior on borderColor {}
    // BasicColorBehavior on disabledColor {}
}
