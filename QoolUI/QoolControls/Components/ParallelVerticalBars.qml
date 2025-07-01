import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property real barWidth: 10
    property real barSpacing: 10
    property real angle: 30

    property alias color: mainPath.fillColor
    property alias strokeColor: mainPath.strokeColor
    property alias strokeWidth: mainPath.strokeWidth
    property alias gradient: mainPath.fillGradient

    readonly property real barOffset: barWidth + barSpacing

    QtObject {
        id: core
        readonly property real rad: root.angle * Math.PI / 180
        readonly property real tangent: Math.tan(rad)

        readonly property int barCount: root.width / root.barOffset
        readonly property int extraBarCount: Math.abs(tangent * root.height) / root.barOffset

        function barlygon(index = 0) {
            let extra_w = tangent * root.height;
            let off = index * root.barOffset;
            let a = Qt.point(0 + off, 0);
            let b = Qt.point(root.barWidth + off, 0);
            let c = Qt.point(extra_w + off, root.height);
            let d = Qt.point(root.barWidth + extra_w + off, root.height);
            return [a, b, d, c];
        }

        function polylines() {
            let result = Array();
            let leftCount = rad > 0 ? extraBarCount : 0;
            let rightCount = rad < 0 ? extraBarCount : 0;
            for (var i = 0 - leftCount; i < barCount + rightCount; i++) {
                result.push(barlygon(i));
            }
            return result;
        }
    }

    ShapePath {
        id: mainPath

        PathMultiline {
            id: lines
            paths: core.polylines()
        }

        // fillColor: "red"
        strokeColor: "transparent"
        strokeWidth: 0
    }
}
