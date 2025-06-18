import QtQuick
import Qool

Item {
    id: root

    property Item item: (parent as Item) ?? this
    property Item relativeFrom: null

    property int fromAnchorPosition: Qore.Center
    property int toAnchorPosition: Qore.Center

    property real xOffset: 0
    property real yOffset: 0
    property real horizontalSpacing: 0
    property real verticalSpacing: 0

    readonly property bool isValid: root.item !== null && root.relativeFrom !== null
    readonly property bool isActive: root.isValid && root.enabled && Component.completed

    visible: false

    QtObject {
        id: pCtrl
        readonly property Item parentSpace: root.item?.parent ?? null
        readonly property point fromPoint: {
            const _x = root.relativeFrom?.x ?? parentSpace?.x ?? 0;
            const _y = root.relativeFrom?.y ?? parentSpace?.x ?? 0;
            const _w = root.relativeFrom?.width ?? parentSpace?.width ?? 0;
            const _h = root.relativeFrom?.height ?? parentSpace?.height ?? 0;
            if (root.relativeFrom)
                var r = root.relativeFrom.mapToItem(parentSpace, _x, _y, _w, _h);
            else
                var r = Qt.rect(_x, _y, _w, _h);
            const p = Qore.positions.posInRect(r, root.fromAnchorPosition);
            return p;
        }
        readonly property vector2d anchorVector: {
            return Qore.positions.offsetToPos(root.item, root.toAnchorPosition);
        }
        function takeSign(x) {
            if (x > 0)
                return 1;
            if (x < 0)
                return -1;
            return 0;
        }

        readonly property real xSpacing: {
            const a = root.horizontalSpacing;
            const s = takeSign(anchorVector.x);
            return a * s;
        }
        readonly property real ySpacing: {
            const a = root.verticalSpacing;
            const s = takeSign(anchorVector.y);
            return a * s;
        }

        readonly property real targetX: pCtrl.fromPoint.x + pCtrl.anchorVector.x + pCtrl.xSpacing + root.xOffset
        readonly property real targetY: pCtrl.fromPoint.y + pCtrl.anchorVector.y + pCtrl.ySpacing + root.yOffset
    } //pCtrl

    Binding {
        when: root.isActive
        target: root.item
        property: "x"
        value: pCtrl.targetX
    }

    Binding {
        when: root.isActive
        target: root.item
        property: "y"
        value: pCtrl.targetY
    }

    function dumpInfo() {
        console.log("active:", root.isActive);
        console.log("from", pCtrl.fromPoint);
        console.log("anchorVector", pCtrl.anchorVector);
        console.log("to", Qt.point(pCtrl.targetX, pCtrl.targetY));
    }
}
