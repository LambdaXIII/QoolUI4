import QtQuick
import Qool.Controls.Components

BasicControlFrame {
    id: root

    property bool animationEnabled: parent?.animationEnabled
                                    ?? Qore.animationEnabled

    property color disabledColor: Qore.style.negative
    ControlLockedCover {
        color: disabledColor
    }
}
