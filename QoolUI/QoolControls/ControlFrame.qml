import QtQuick
import Qool.Controls.Components

BasicControlFrame {
    id: root

    property bool animationEnabled: parent?.animationEnabled
                                    ?? Qore.animationEnabled

    ControlLockedCover {}
    // ControlDisabledBorder {}
}
