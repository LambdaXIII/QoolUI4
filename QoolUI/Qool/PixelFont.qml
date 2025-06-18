pragma Singleton

import QtQuick

FontLoader {
    id: root
    source: "assets/MozartNBP.ttf"

    property font normalFont
    normalFont {
        family: root.font.family
        pixelSize: 8
    }
}
