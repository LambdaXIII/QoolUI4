// CycleChoiceButton 拍平件（暂不耦合 Controls，Color 内部消费）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color

T.AbstractButton {
    id: root

    // Templates 不传播 contentItem implicit，显式回传（Text 自带 80x40 最小尺寸）。
    implicitWidth: contentItem.implicitWidth
    implicitHeight: contentItem.implicitHeight

    property string fallbackText: qsTr("<空>")
    property color fallbackColor: root.Style.text

    property var texts: root.Style.papaWords
    property var colors: [root.Style.text, root.Style.highlight]
    property var values: []
    property var backgrounds: []
    property var datas: []

    readonly property int length: root.texts.length


    property alias currentIndex: counter.current
    property alias defaultIndex: counter.defaultValue
    // 实数环绕（非裁剪语义，勿当 bug 修）。
    readonly property int safeCurrentIndex: _limit_cycle_real(
        counter.current, counter.min, counter.max + 1)

    property bool keepIndexSafe: false


    readonly property string displayText: _get_text(root.currentIndex)
    readonly property color displayColor: _get_color(root.currentIndex)
    readonly property var currentData: root.dataAt(root.currentIndex)

    property color highlightColor: root.displayColor ?? root.Style.highlight

    property int horizontalAlignment: Text.AlignRight
    property int verticalAlignment: Text.AlignVCenter


    property bool showTitle: false
    property string title: ""
    property Component titleComponent: titleText
    readonly property Item titleItem: titleLoader.item

    property QtObject bgSettings: QtObject {
        id: bgSettingsObj
        property real cutSize: root.Style.controlCutSize
        property real strokeWidth: root.Style.controlBorderWidth
        property color strokeColor: root.Style.controlBorderColor
        property color color: root.Style.controlBackgroundColor
    }

    // cutSizes 便捷面删为四角显式（_private 不在兼容范围）。
    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        cutSizeTL: root.bgSettings.cutSize
        cutSizeTR: root.bgSettings.cutSize
        cutSizeBL: root.bgSettings.cutSize
        cutSizeBR: root.bgSettings.cutSize
        borderWidth: root.bgSettings.strokeWidth
        fillColor: root.bgSettings.color
        borderColor: root._feedbackBorderColor
        curved: false
    }

    readonly property color _feedbackBorderColor: {
        if (!root.enabled)
            return root.Style.negative
        if (root.hovered || root.checked)
            return root.highlightColor
        return root.bgSettings.strokeColor
    }

    font.pixelSize: root.Style.controlTextSize
    hoverEnabled: true

    readonly property real headerSpace: {
        if (!root.showTitle)
            return 0
        return Math.max(titleLoader.height + titleLoader.anchors.topMargin,
                        root.bgSettings.cutSizeTL)
    }

    topPadding: root.topInset + root.bgSettings.strokeWidth + headerSpace
    leftPadding: root.leftInset + root.bgSettings.strokeWidth
                 + (root.showTitle ? 0 : root.bgSettings.cutSizeTL)
    rightPadding: root.rightInset + root.bgSettings.strokeWidth
    bottomPadding: root.bottomInset + root.bgSettings.strokeWidth

    QtObject {
        id: counter
        property int min: 0
        property int max: Math.max(root.texts.length - 1, 0)
        property int defaultValue: 0
        // 首次交互写入后与 defaultValue 的绑定断开（QML 赋值语义）。
        property int current: defaultValue

        function _validate(x) {
            if (root.keepIndexSafe) {
                if (x > max)
                    return min
                if (x < min)
                    return max
            }
            return x
        }

        function next() {
            current = _validate(current + 1)
        }

        function previous() {
            current = _validate(current - 1)
        }

        function reset() {
            current = _validate(defaultValue)
        }
    } //counter

    contentItem: Text {
        id: mainText
        text: root.displayText
        color: root.displayColor
        font: root.font
        elide: Text.ElideMiddle
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
    } //mainText

    background: QoolBox {
        id: bgBox
        settings: root.backgroundSettings
        implicitWidth: 80
        implicitHeight: 40
    }

    Rectangle {
        id: hoverGradient
        anchors {
            fill: parent
            topMargin: root.topInset
            leftMargin: root.leftInset
            bottomMargin: root.bottomInset
            rightMargin: root.rightInset
        }
        border.width: 0
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.5
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: root.highlightColor
            }
        }
        opacity: root.enabled && root.hovered ? 0.2 : 0
        z: 2
    } //hoverGradient

    QoolBox {
        id: pressedCover
        anchors {
            fill: parent
            topMargin: root.topInset
            leftMargin: root.leftInset
            bottomMargin: root.bottomInset
            rightMargin: root.rightInset
        }
        settings: QoolBoxSettings {
            cutSizeTL: root.bgSettings.cutSize
            cutSizeTR: root.bgSettings.cutSize
            cutSizeBL: root.bgSettings.cutSize
            cutSizeBR: root.bgSettings.cutSize
            fillColor: root.highlightColor
            borderWidth: 0
            curved: false
        }
        opacity: root.down ? 0.25 : 0
        z: 90
    } //pressedCover

    QoolBox {
        id: lockedCover
        anchors {
            fill: parent
            topMargin: root.topInset
            leftMargin: root.leftInset
            bottomMargin: root.bottomInset
            rightMargin: root.rightInset
        }
        settings: QoolBoxSettings {
            cutSizeTL: root.bgSettings.cutSize
            cutSizeTR: root.bgSettings.cutSize
            cutSizeBL: root.bgSettings.cutSize
            cutSizeBR: root.bgSettings.cutSize
            fillColor: root.Style.negative
            borderWidth: 0
            curved: false
        }
        z: 90
        // BasicNumberBehavior on opacity：动画已按临时件策略移除。
    } //lockedCover

    Loader {
        id: titleLoader
        z: 20
        active: root.showTitle
        sourceComponent: root.titleComponent
        anchors {
            top: parent.top
            right: parent.right
            topMargin: root.bgSettings.strokeWidth + 1 + root.topInset
            rightMargin: root.bgSettings.strokeWidth + 1 + root.rightInset
        }
    } //titleLoader

    Component {
        id: titleText
        Text {
            text: root.title
            color: root.Style.placeholderText
            font.pixelSize: root.Style.decorativeTextSize
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignTop
        }
    }

    onClicked: goForward()

    function goForward() {
        counter.next()
    }

    function goBackward() {
        counter.previous()
    }

    function reset() {
        counter.reset()
    }

    function _cycle_index(index, length) {
        if (length <= 0)
            return -1
        if (index >= 0 && index < length)
            return index
        let fixed = index % length
        if (fixed < 0)
            fixed += length
        return fixed
    }

    function _fetch(index, list) {
        const i = _cycle_index(index, list.length)
        if (i < 0 || i >= list.length)
            return undefined
        return list[i]
    }

    function textAt(index) {
        if (root.texts.length === 0)
            return ""
        return root.texts[_cycle_index(index, root.texts.length)]
    }

    function valueAt(index) {
        if (root.values.length === 0)
            return root.textAt(index)
        return _fetch(index, root.values)
    }

    function colorAt(index) {
        return _fetch(index, root.colors)
    }

    function backgroundAt(index) {
        return _fetch(index, root.backgrounds)
    }

    function dataAt(index) {
        return _fetch(index, root.datas)
    }

    function indexOfText(v) {
        return root.texts.indexOf(v)
    }

    function indexOfValue(v) {
        return root.values.indexOf(v)
    }

    function _get_text(index) {
        const t = root.textAt(index)
        return t === "" ? root.fallbackText : t
    }

    function _get_color(index) {
        if (root.colors.length === 0)
            return root.fallbackColor
        return root.colors[_cycle_index(index, root.colors.length)]
    }

    // 实数 cycle（末尾 -1 以包含最小值，边界刻意异于 int cycle，勿改）。
    function _limit_cycle_real(value, min, max) {
        if (min === max)
            return min
        const lo = Math.min(min, max)
        const hi = Math.max(min, max)
        if (value >= lo && value <= hi)
            return value
        const distance = Math.abs(hi - lo)
        const offset = value - lo
        const _x = offset / distance
        let fixed = offset - Math.trunc(_x) * distance
        if (fixed < 0)
            fixed += distance
        return lo + fixed - 1 // -1 以包含最小值
    }
}
