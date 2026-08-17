pragma ComponentBehavior: Bound

import QtQuick
import Qool
import "NumTools.js" as Tools
import Qool.Color

// 色名列表视图：分类色名 + 互斥点选。
//
// 以 ColorNameHQ.names(category) 为模型展示色名列表，
// 每行一个 ColorNameButton；点选互斥（同一时刻至多一项选中，
// 独占组语义）。
//
// 属性
// - 属性 `category`（string）：当前分类。
//   模型为 ColorNameHQ.names(category)；改值即换列表内容。
//   默认 `"DEFAULT"`（与默认色名插件的分类一致）。
// - 属性 `font`（font）：色名行字体，默认 PixelFont.normal。
// - 属性 `currentColor`（color）：只读，当前选中行的颜色
//   （ColorNameButton.color）。取消选中后保持最后一次选中值
//   （deselect 不清空 currentColor）。
//
// 方法
// - 方法 deselect()：取消当前选中（等价点击已选中的行，见组件内
//   pControl 互斥逻辑）。仅供 ColorNameList 外部同步使用。
//
// 易误解点
// - 点选互斥是独占组语义：点击已选中的行保持选中，不会取消
//   ——取消只能经 deselect()。
// - `currentColor` 在取消选中后不重置，因此外部
//   改色后 deselect() 不会触发 `currentColorChanged` 回写。
ListView {
    id: root

    property string category: "DEFAULT"

    property font font: PixelFont.normal

    readonly property color currentColor: pControl.currentColor

    function deselect() {
        if (pControl.checkedButton)
            pControl.checkedButton.checked = false
    }

    model: ColorNameHQ.names(root.category)

    // 选中控制：checkedButton 互斥引用 + currentColor。
    QtObject {
        id: pControl
        property color currentColor
        property ColorNameButton checkedButton
        onCheckedButtonChanged: {
            if (pControl.checkedButton)
                pControl.currentColor = pControl.checkedButton.color
        }
    } //pControl

    delegate: ColorNameButton {
        required property string modelData
        id: dele
        name: modelData
        width: ListView.view.width - scroller.width
        font: root.font
        group: pControl
    } //dele

    // 内联滚动条（指示条 + 顶部/底部/中部三区点击跳转）。
    Item {
        id: scroller
        property Flickable target: root
        property color color: root.Style.toolTipBase
        property bool animationEnabled: root.Style.animationEnabled

        implicitWidth: 4
        width: target.visibleArea.heightRatio >= 1.0 ? 0 : implicitWidth
        visible: width > 0

        x: parent.width - width
        height: parent.height

        // 指示条：随可见区比例伸缩、随滚动位置移动。
        Rectangle {
            id: indicator
            color: scroller.color
            radius: scroller.implicitWidth / 2
            border.width: 0
            width: scroller.width
            height: scroller.target.visibleArea.heightRatio * scroller.height
            y: scroller.target.visibleArea.yPosition * scroller.height
            // 刻意用真实属性 runnint（高度动画期间指示条保持可见）；
            // 勿当拼写错误"修正"为 running——running 为死访问。
            opacity: scroller.target.movingVertically
                     || heightBehavior.runnint ? 1 : 0.2
            BasicNumberBehavior on opacity {
                duration: root.Style.movementDuration
            }
            BasicNumberBehavior on height {
                id: heightBehavior
            }
        } //indicator

        // 顶部点击区：跳到列表起点。
        MouseArea {
            id: topMA
            width: Math.max(scroller.width, 20)
            height: Tools.limitNumber(scroller.width, scroller.height / 2, 20)
            x: (scroller.width - width) / 2
            y: (scroller.width - height) / 2
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                let target_y = 0
                scroller.target.cancelFlick()
                if (scroller.animationEnabled) {
                    jumpAnimation.stop()
                    jumpAnimation.to = target_y
                    jumpAnimation.start()
                } else
                    scroller.target.contentY = target_y
            }
        } //topMA

        // 底部点击区：跳到列表终点。
        MouseArea {
            id: bottomMA
            width: Math.max(scroller.width, 20)
            height: Tools.limitNumber(scroller.width, scroller.height / 2, 20)
            x: (scroller.width - width) / 2
            y: (scroller.width - height) / 2 + (scroller.height - scroller.width)
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                let target_y = scroller.target.contentHeight
                              * (1 - scroller.target.visibleArea.heightRatio)
                scroller.target.cancelFlick()
                if (scroller.animationEnabled) {
                    jumpAnimation.stop()
                    jumpAnimation.to = target_y
                    jumpAnimation.start()
                } else
                    scroller.target.contentY = target_y
            }
        } //bottomMA

        // 中部点击区：按点击比例跳到列表对应位置。
        MouseArea {
            id: centerMA
            width: Math.max(scroller.width, 20)
            x: topMA.x
            anchors.top: topMA.bottom
            anchors.bottom: bottomMA.top
            cursorShape: Qt.CrossCursor
            onClicked: ev => {
                           let root_point = mapToItem(scroller, ev.x, ev.y)
                           let real_y = root_point.y
                           let ratio = real_y / scroller.height
                           let target_y = scroller.target.contentHeight
                                         * Math.min(
                               ratio,
                               1 - scroller.target.visibleArea.heightRatio)
                           if (scroller.animationEnabled) {
                               jumpAnimation.stop()
                               jumpAnimation.to = target_y
                               jumpAnimation.start()
                           } else
                               scroller.target.contentY = target_y
                       }
        } //centerMA

        NumberAnimation {
            id: jumpAnimation
            target: scroller.target
            property: "contentY"
            easing.type: Easing.InOutQuad
            duration: root.Style.movementDuration
        } //jumpAnimation
    } //scroller
}
