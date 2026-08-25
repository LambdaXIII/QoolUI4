import QtQuick
import Qool

SmartObject {
    id: root

    property QtObject target1
    property string property1

    property QtObject target2
    property string property2

    PropertyProxy {
        id: p1
        target: root.target1
        property: root.property1
        onValueChanged: {
            let v1 = p1.value;
            if (p2.value === v1)
                return;
            p2.value = v1;
        }
    }

    PropertyProxy {
        id: p2
        target: root.target2
        property: root.property2
        onValueChanged: {
            let v2 = p2.value;
            if (p1.value === v2)
                return;
            p1.value = v2;
        }
    }
}
