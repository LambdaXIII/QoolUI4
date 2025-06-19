import QtQuick
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

        function takeSign(x) {
            if (x > 0)
                return 1;
            if (x < 0)
                return -1;
            return 0;
        }

        readonly property point fromPos: {
            const pos = Qore.positions.posInRect(root.linkTo, root.linkToAnchorPosition);
            return root.linkTo.mapToGlobal(pos);
        }

        readonly property vector2d targetOffset: {
            const vec = Qore.positions.offsetToPos(root.target, root.targetAnchorPosition);
            return vec;
        }

        readonly property vector2d spacingOffset: {
            const x = root.horizontalSpacing * takeSign(targetOffset.x);
            const y = root.verticalSpacing * takeSign(targetOffset.y);
            return Qt.vector2d(x, y);
        }
    }//pCtrl

    readonly property real globalTargetX: pCtrl.fromPos.x + pCtrl.targetOffset.x + pCtrl.spacingOffset.x + root.xOffset
    readonly property real globalTargetY: pCtrl.fromPos.y + pCtrl.targetOffset.y + pCtrl.spacingOffset.y + root.yOffset
    readonly property point globalTargetPos: Qt.point(globalTargetX, globalTargetY)

    Binding {
        when: root.autoLink && root.enabled && root.target.parent
        target: root.target
        property: "x"
        value: root.target.parent.mapFromGlobal(root.globalTargetPos).x
    }
    Binding {
        when: root.autoLink && root.enabled && root.target.parent
        target: root.target
        property: "y"
        value: root.target.parent.mapFromGlobal(root.globalTargetPos).y
    }

    function dumpInfo() {
        pCtrl.dumpProperties();
        dumpProperties();
    }
}
