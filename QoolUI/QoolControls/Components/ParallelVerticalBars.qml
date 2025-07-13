import QtQuick
import QtQuick.Shapes
import Qool

Shape {
    id: root

    property real barWidth: 10
    property real barSpacing: 10
    property real angle: 30

    property alias color: mainPath.fillColor
    property alias strokeColor: mainPath.strokeColor
    property alias strokeWidth: mainPath.strokeWidth
    property alias gradient: mainPath.fillGradient
    property alias fillItem: mainPath.fillItem

    readonly property real barOffset: barWidth + barSpacing
    readonly property int extraBarCount: core.extraBarCount

    property real offset: 0 //horizontally moves shape

    implicitWidth: 200
    implicitHeight: 200

    SmartObject {
        id: core
        readonly property real rad: root.angle * Math.PI / 180
        readonly property real tangent: Math.tan(rad)

        readonly property int barCount: root.width / root.barOffset
        readonly property int extraBarCount: Math.round(
                                                 Math.abs(
                                                     tangent * root.height) / root.barOffset)

        function barlygon(index = 0) {
            let extra_w = tangent * root.height
            let off = index * root.barOffset + root.offset
            let a = Qt.point(0 + off, 0)
            let b = Qt.point(root.barWidth + off, 0)
            let c = Qt.point(extra_w + off, root.height)
            let d = Qt.point(root.barWidth + extra_w + off, root.height)
            return [a, b, d, c]
        }

        function barIndexesRange() {
            let result = Object()
            let leftCount = rad > 0 ? extraBarCount : 0
            let rightCount = rad < 0 ? extraBarCount : 0
            result["left"] = 0 - (leftCount + 1)
            result["right"] = barCount + rightCount + 1
            return result
        }

        function polylines() {
            let result = Array()
            let indexRange = barIndexesRange()
            for (var i = indexRange.left; i <= indexRange.right; i++) {
                let shape = barlygon(i)
                result.push(shape)
            }
            return result
        }
    }

    ShapePath {
        id: mainPath

        PathMultiline {
            id: lines
            paths: core.polylines()
        }

        strokeColor: "transparent"
        strokeWidth: 0
    }
}
