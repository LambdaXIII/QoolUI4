pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Controls
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls
import Qool.Debug

BasicPage {
    id: root

    title: qsTr("试炼场")
    note: qsTr("测试一些东西……")

    Rectangle {
        id: r
        color: "transparent"
        border.width: 2
        border.color: "red"
        width: 400
        height: 400
        x: 50
        y: 50

        property real startAngle: -45
        property real endAngle: 45

        ShapeControl {
            id: control
            CircleGadget {
                id: circle
                CirclePoint {
                    id: ppa
                    angle: r.startAngle - 90
                }
            }
            property point pA: circle.pointFromAngle(r.startAngle)
            property point pB: circle.pointFromAngle(r.endAngle)
            Connections {
                target: circle
                function onCircleChanged() {
                    control.pA = circle.pointFromAngle(r.startAngle - 90);
                    control.pB = circle.pointFromAngle(r.endAngle - 90);
                }
            }
        }

        RectResizer {}

        PointIndicator {
            point: circle.center
        }

        PointIndicator {
            point: ppa.position
            name: "startPoint"
        }

        PointIndicator {
            point: control.pB
        }
    }

    Component.onCompleted: {
        // console.log(circle.target);
        console.log(ppa.attachedCircle);
    }
}
