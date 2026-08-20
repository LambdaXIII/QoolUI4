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
        objectName: "colorMapper" // 采样契约可观察点（测试经 dial.data 定位）
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
        // valueColor 不经绑定——colorAt 为 C++ 方法、QML 绑定不追踪方法体
        // 内 stops 访问（同 Slider handle 缺陷：直接绑定冻结初始采样、源色
        // 变化不触发重算）。由 onCompleted 初始采样 + 信号 connect 手动驱动
        // 真实更新时机（position 变 / high/mid/low 色任一变）。
        property color valueColor

        function updateValueColor() {
            valueColor = colorAt(root.position)
        }

        Component.onCompleted: {
            updateValueColor()
            root.positionChanged.connect(updateValueColor)
            root.highColorChanged.connect(updateValueColor)
            root.midColorChanged.connect(updateValueColor)
            root.lowColorChanged.connect(updateValueColor)
        }
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
                y: Math.min(
                       root.background.width,
                       root.background.height) * 0.4 * -1 + handleItem.height / 2
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
