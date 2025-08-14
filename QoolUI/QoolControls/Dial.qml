import QtQuick
import QtQuick.Templates as T
import Qool
import "_private"

T.Dial {
    id: root

    property color highColor: Style.red
    property color midColor: Style.yellow
    property color lowColor: Style.green

    ColorMapper {
        id: colorMapper
        ColorMapperStop {
            position: 0
            color: root.lowColor
        }
        ColorMapperStop {
            position: 0.5
            color: root.midColor
        }
        ColorMapperStop {
            position: 1
            color: root.highColor
        }
        readonly property color valueColor: colorAt(root.position)
    }

    background: Rectangle {
        id: bgbox
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        implicitWidth: 50
        implicitHeight: 50

        width: Math.max(35, Math.min(root.width, root.height))
        height: width
        radius: width / 2
        border.color: root.Style.buttonText
        color: root.Style.controlBackgroundColor
        border.width: root.Style.controlBorderWidth

        DialRangeArc {
            id: rangeArc
            anchors.fill: parent
            startAngle: root.startAngle
            endAngle: root.endAngle
            highColor: root.highColor
            midColor: root.midColor
            lowColor: root.lowColor
            opacity: 0
        }
    }

    handle: Rectangle {
        id: handleItem
        x: root.background.x + (root.background.width - width) / 2
        y: root.background.y + (root.background.height - height) / 2
        width: Math.max(4, Math.min(root.width, root.height) * 0.05)
        height: Math.max(root.background.width * 0.3, 4)
        radius: width / 2
        color: root.Style.buttonText
        transform: [
            Translate {
                y: Math.min(root.background.width, root.background.height) * 0.4 * -1
                   + handleItem.height / 2
            },
            Rotation {
                angle: root.angle
                origin.x: handleItem.width / 2
                origin.y: handleItem.height / 2
            }
        ]
    }

    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    Binding {
        when: root.pressed
        handleItem.color: colorMapper.valueColor
        rangeArc.opacity: 1
    }
}
