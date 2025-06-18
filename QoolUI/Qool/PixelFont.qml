pragma Singleton

import QtQuick

FontLoader {
    id: root
    source: "assets/MozartNBP.ttf"
    readonly property string family: font.family

    property font normal
    normal {
        family: root.font.family
        pixelSize: 24
    }
}
