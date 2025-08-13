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

    Dial {
        id: d
        width: 300
        height: 300
        // startAngle: -45
        // endAngle: 45

        RectResizer {}
    }

    NumberMapper {
        id: mapper
        NumberMapperStop {
            position: 0
            value: -100
        }
        NumberMapperStop {
            position: 0.5
            value: 50
        }

        NumberMapperStop {
            position: 1
            value: 0
        }

        Component.onCompleted: {
            console.log(mapper.valueAt(0), mapper.valueAt(0.25), mapper.valueAt(0.5),
                        mapper.valueAt(1));
        }
    }
}
