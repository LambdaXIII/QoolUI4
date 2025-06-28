import QtQuick
import Qool

Item {
    id: root

    property Item axisItem: parent
    property Item target: this
    property Item lockTo: axisItem

    property bool autoLock: true

    property int targetAnchorPosition: Qore.TopLeft
    property int lockToAnchorPosition: Qore.TopLeft

    property real horizontalSpacing: 0
    property real verticalSpacing: 0

    property real xOffset: 0
    property real yOffset: 0

    SmartObject {
        id: pCtrl

        function takeSign(x) {
            if (x > 0)
                return 1
            if (x < 0)
                return -1
            return 0
        }

        readonly property point basePos: {
            const x = Qore.positions.xPosFromWidth(root.lockTo.width,
                                                   root.lockToAnchorPosition)
            const y = Qore.positions.yPosFromHeight(root.lockTo.height,
                                                    root.lockToAnchorPosition)
            return root.axisItem.mapFromItem(root.lockTo, x, y)
        }

        readonly property real targetMovementX: {
            return Qore.positions.xOffsetToPos(root.target.width,
                                               root.targetAnchorPosition)
        }
        readonly property real targetMovementY: {
            return Qore.positions.yOffsetToPos(root.target.height,
                                               root.targetAnchorPosition)
        }

        readonly property real targetSpacingX: root.horizontalSpacing * takeSign(
                                                   basePos.x + targetMovementX)
        readonly property real targetSpacingY: root.verticalSpacing * takeSign(
                                                   basePos.y + targetMovementY)
    } //pCtrl

    readonly property real targetX: pCtrl.basePos.x + pCtrl.targetMovementX
                                    + pCtrl.targetSpacingX + root.xOffset
    readonly property real targetY: pCtrl.basePos.y + pCtrl.targetMovementY
                                    + pCtrl.targetSpacingY + root.yOffset

    Binding {
        target: root.target
        property: "x"
        value: root.targetX
        when: root.enabled && root.autoLock
    }

    Binding {
        target: root.target
        property: "y"
        value: root.targetY
        when: root.enabled && root.autoLock
    }
}
