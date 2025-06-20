pragma Singleton

import QtQuick
import Qool

SmartObject {
    id: root
    property bool animationEnabled: true

    readonly property real windowCutSize: 40
    readonly property real windowBorderWidth: 1

    readonly property int transitionDuration: 200
    readonly property int movementDuration: 400

    readonly property color positiveColor: "#00FF68"
    readonly property color negativeColor: "#FF414D"
}
