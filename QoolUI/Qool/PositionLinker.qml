import QtQuick
import QtQuick.Controls
import Qool

SmartObject {
    id: root

    property Item target: parentItem ?? dummyFromItem
    property Item linkTo: dummyToItem

    property int targetAnchorPosition: Qore.Center
    property int linkToAnchorPosition: Qore.Center

    property real horizontalSpacing: 0
    property real verticalSpacing: 0

    property real xOffset: 0
    property real yOffset: 0

    property bool autoLink: true

    SmartObject {
        id: pCtrl
        Item {
            id: dummyFromItem
        }
        Item {
            id: dummyToItem
        }

        readonly property rect fromRect: {
            const w = root.linkTo.width;
            const h = root.linkTo.y;
            const r = Overlay.overlay.mapFromItem(root.linkTo, 0, 0, w, h);
            return r;
        }
        readonly property point fromPosX: {
            const r = pCtrl.fromRect;
            return Qore.positions.xPosInRect(r, root.linkToAnchorPosition);
        }
        readonly property point fromPosY: {
            const r = pCtrl.fromRect;
            return Qore.positions.yPosInRect(r, root.linkToAnchorPosition);
        }

        readonly property rect toRect: {
            const w = root.target.width;
            const h = root.target.height;
            const r = Overlay.overlay.mapFromItem(root.target, 0, 0, w, h);
            return r;
        }
        readonly property real toPosX: {
            const r = pCtrl.toRect;
            return Qore.positions.xPosInRect(r, root.targetAnchorPosition);
        }
        readonly property real toPosY: {
            const r = pCtrl.toRect;
            return Qore.positions.yPosInRect(r, root.targetAnchorPosition);
        }

        readonly property real toOffsetX: Qore.positions.xOffsetToPos(root.target, root.targetAnchorPosition)
        readonly property real toOffsetY: Qore.positions.yOffsetToPos(root.target, root.targetAnchorPosition)

        function takeSign(x) {
            if (x > 0)
                return 1;
            if (x < 0)
                return -1;
            return 0;
        }

        readonly property real xSpacing: root.horizontalSpacing * takeSign(toOffsetX)
        readonly property real ySpacing: root.verticalSpacing * takeSign(toOffsetY)

        readonly property real globalTargetX: fromPosX + toPosX + toOffsetX + xSpacing + root.xOffset
        readonly property real globalTargetY: fromPosY + toPosY + toOffsetY + ySpacing + root.yOffset
    }//pCtrl

    readonly property point targetPos: Overlay.overlay.mapToItem(root.target, pCtrl.globalTargetX, pCtrl.globalTargetY)

    readonly property real targetX: targetPos.x
    readonly property real targetY: targetPos.y

    Binding {
        when: root.autoLink && root.enabled
        target: root.target
        property: "x"
        value: root.targetX
    }
    Binding {
        when: root.autoLink && root.enabled
        target: root.target
        property: "y"
        value: root.targetY
    }
}
