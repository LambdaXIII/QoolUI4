// NOTE(拍平件定位) v3 CycleChoiceButton 的拍平重写件，置于 Qool.Color/_private
// 而非 v4 Qool.Controls：暂不耦合 v4 Controls（拍平件只被 Color 模块内部消费），
// 直接以 QtQuick 原语 + Qool 核心类型实现。
// TODO(将来迁移): 待 Color 模块稳定后，本件扩展为完整控件迁移至 v4 Qool.Controls
// （届时 Color 切换依赖，废弃本私有版）——见 color-migration-spec §7-7。
//
// 拍平内容（v3 → 本文件内联）：
//   - CycleChoiceButton    （循环切换按钮框架，本文件根，T.AbstractButton 原语）
//   - ComboChoiceModel     （C++ 模型取消 → texts/colors/values/backgrounds/datas
//                           数组属性 + textAt/valueAt/... 方法内联，循环取模照迁）
//   - CycleChoiceText      （显示文字/颜色 + 切换动画内联为 contentItem Text）
//   - IntegerCounter       （counter QtObject 内联：JumpToOtherSide/NoLimits 语义）
//   - NumberLimiter        （safeCurrentIndex 的 CycleBetweenEdges 实数环绕内联）
//   - BasicText_ButtonContent（文字切换弹跳动画 → BasicTextBehavior 等价）
// 不再依赖：QtQuick.Controls / Qool.Controls / Qool.Controls.Basic / numberhelper /
// Qool.Controls.Components（v3 的 Control*Cover 三件套以纯原语等效覆盖实现，见下）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color

/*!
    \qmltype CycleChoice
    \inqmlmodule Qool.Color
    \brief 循环切换按钮拍平件（v3 \c CycleChoiceButton 全功能拍平）。

    点击按钮在选项数组中循环前进（\c goForward()），提供 \c goBackward() /
    \c reset() 反向与复位；\c currentIndex 为当前选项下标，
    \c displayText / \c displayColor 为当前选项的文字与颜色。

    \section2 数组属性（v3 ComboChoiceModel 取消，内联）
    v3 的 \c ComboChoiceModel（C++ QAbstractListModel）不再需要——数据面拍平为
    数组属性：\c texts（必选，默认 \c Style.papaWords）、\c colors（默认
    [text, highlight]）、\c values / \c backgrounds / \c datas（可选扩展面，
    默认空）。配套方法 \c textAt() / \c valueAt() / \c colorAt() /
    \c backgroundAt() / \c dataAt() / \c indexOfText() / \c indexOfValue()
    与 v3 模型方法同名同语义；\c length 为 \c texts 长度。\c currentData 为
    \c dataAt(currentIndex)（\c datas 为空时返回 undefined，与 v3 空
    QVariant 语义等价）。
    \b 越界语义照迁：所有 \c xxxAt() 对下标做\b 循环取模（v3
    \c fetch_value 的 int cycle），即下标 -1 取末项、length 取首项，永不越界。

    \section2 循环/限幅逻辑（v3 IntegerCounter/NumberLimiter 内联）
    \list
    \li \c counter（内部 QtObject）实现 v3 \c IntegerCounter：
        \c currentIndex / \c defaultIndex 为别名；\c keepIndexSafe 为 true 时
        计数采用 \c JumpToOtherSide（越过上界跳回最小值、越过下界跳回最大值），
        false 时 \b 无限制（\c NoLimits，v3 默认）——此时 \c currentIndex 可越界，
        由 \c xxxAt() 的循环取模兜底显示。
    \li \c safeCurrentIndex 为 \c NumberLimiter(CycleBetweenEdges) 对
        [\c counter.min, \c counter.max + 1] 的\b 实数环绕结果（v3 原样，
        含 x3_number_tools 实数版 cycle 的 \c -1 修正，见函数实现注释）——
        \b 注意它不是"裁剪到有效索引"的语义，是 v3 的逐字行为，勿当 bug 修。
    \li \c current 初始为 \c defaultValue 的 QML 绑定（v3 同款写法）；首次
        交互（next/previous/reset 写入）后绑定断开、独立变化——与 v3 一致。
    \li 差异注明：v3 中直接写 \c currentIndex 会经 C++ setter 校验（按
        counterBehavior 限幅）；拍平件中直接写 \c currentIndex 原样接受
        （仅 next/previous 路径校验）。Color 模块无直接写 currentIndex 的
        消费方，故行为不受影响。
    \endlist

    \section2 交互反馈（v3 Control*Cover 的简化等效）
    v3 的 \c ControlPressedCover（PaPaWall 词墙）/ \c ControlLockedCover
    （条纹滚动）装饰性效果在 \c import 约束下（仅 QtQuick/Qool）以纯原语
    半透明覆盖等效实现：按下 → 高亮色覆盖（\c pressedCover，opacity 0.25）；
    禁用 → 负面色覆盖（\c lockedCover，opacity 0.25）+ 边框变负面色；
    悬停/选中 → 边框高亮 + 底部渐变淡光。状态反馈保留，装饰渲染简化。

    \section2 showTitle 默认变更（与 v3 的刻意差异）
    v3 \c CycleChoiceButton 默认 \c showTitle: true 且继承占位标题
    \c qsTr("酷酷的按钮")，导致每个按钮右上角泄漏占位文字（遗留缺陷）。
    拍平件保留 \c showTitle / \c title / \c titleComponent / \c titleItem
    完整能力，默认 \c showTitle: false、\c title: ""——能力不降级，默认外观修正。

    \section2 为什么在 Color/_private 而非 Controls
    同 \l NumInput：暂不耦合 v4 Controls，TODO 将来迁移（见文件头注释）。

    \section2 属性
    \c texts / \c colors 为数据面；\c currentIndex / \c defaultIndex /
    \c safeCurrentIndex / \c keepIndexSafe 为计数面；\c displayText /
    \c displayColor / \c currentData 为只读当前项；\c highlightColor 驱动
    悬停/按下反馈（默认跟随 \c displayColor）；\c fallbackText（默认
    qsTr("<空>")，保持 v3 渲染行为——v3 的根 fallbackText 未参与渲染，
    实际渲染用的是 CycleChoiceText 内层 "<空>"，拍平合并为单属性）/
    \c fallbackColor 为空数据兜底；\c bgSettings（v3 OctagonSettings API
    对位：cutSize/strokeWidth/strokeColor/color）与 \c backgroundSettings
    （v4 惯例 QoolBoxSettings 对象，borderColor 受状态驱动）控制背景外观。
*/

T.AbstractButton {
    id: root

    // ===== 数据面（v3 ComboChoiceModel 数组属性内联）=====

    // 空数据/空文字兜底（默认 "<空>" 为 v3 实际渲染行为，见类文档）。
    property string fallbackText: qsTr("<空>")
    property color fallbackColor: root.Style.text

    property var texts: root.Style.papaWords
    property var colors: [root.Style.text, root.Style.highlight]
    property var values: []
    property var backgrounds: []
    property var datas: []

    readonly property int length: root.texts.length

    // ===== 计数面（v3 IntegerCounter + NumberLimiter 内联）=====

    property alias currentIndex: counter.current
    property alias defaultIndex: counter.defaultValue
    // v3 NumberLimiter(CycleBetweenEdges) 对 [0, max+1] 的实数环绕，见类文档。
    readonly property int safeCurrentIndex: _limit_cycle_real(
        counter.current, counter.min, counter.max + 1)

    property bool keepIndexSafe: false

    // ===== 当前项只读面 =====

    readonly property string displayText: _get_text(root.currentIndex)
    readonly property color displayColor: _get_color(root.currentIndex)
    readonly property var currentData: root.dataAt(root.currentIndex)

    property color highlightColor: root.displayColor ?? root.Style.highlight

    property int horizontalAlignment: Text.AlignRight
    property int verticalAlignment: Text.AlignVCenter

    // ===== 标题面（v3 BasicButton API 保留；默认关闭，见类文档）=====

    property bool showTitle: false
    property string title: ""
    property Component titleComponent: titleText
    readonly property Item titleItem: titleLoader.item

    // ===== 背景面 =====
    // v3 OctagonSettings API 对位（ColorNameList 等消费方写 bgSettings.cutSize）。
    property QtObject bgSettings: QtObject {
        id: bgSettingsObj
        property real cutSize: root.Style.controlCutSize
        property real strokeWidth: root.Style.controlBorderWidth
        property color strokeColor: root.Style.controlBorderColor
        property color color: root.Style.controlBackgroundColor
    }

    // v4 惯例的 QoolBoxSettings 背景对象；borderColor 由状态驱动
    //（禁用 → 负面色；悬停/选中 → 高亮色；否则背景描边色）。
    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        cutSizes: root.bgSettings.cutSize
        borderWidth: root.bgSettings.strokeWidth
        fillColor: root.bgSettings.color
        borderColor: root._feedbackBorderColor
        curved: false // v3 CutCornerBox 八边形外观
        BasicColorBehavior on borderColor {
            enabled: root.Style.animationEnabled
        }
    }

    readonly property color _feedbackBorderColor: {
        if (!root.enabled)
            return root.Style.negative
        if (root.hovered || root.checked)
            return root.highlightColor
        return root.bgSettings.strokeColor
    }

    // ===== 布局 =====

    font.pixelSize: root.Style.controlTextSize
    hoverEnabled: true

    // v3 BasicButton 标题区高度（showTitle 关闭时为 0）。
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

    // ===== 计数对象（v3 IntegerCounter 内联）=====

    QtObject {
        id: counter
        property int min: 0
        property int max: Math.max(root.texts.length - 1, 0)
        property int defaultValue: 0
        // v3 同款 QML 绑定：current 初始跟随 defaultValue；
        // 首次 next/previous/reset 写入后绑定断开（QML 赋值语义，与 v3 一致）。
        property int current: defaultValue

        // JumpToOtherSide（keepIndexSafe）语义，v3 NumberCounter::_validator 内联。
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

    // ===== 显示（v3 CycleChoiceText + BasicText_ButtonContent 内联）=====

    contentItem: Text {
        id: mainText
        text: root.displayText
        color: root.displayColor
        font: root.font
        elide: Text.ElideMiddle
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment

        // 切换弹跳动画（v3 BasicText_ButtonContent 的 Behavior on text 等价，
        // v4 BasicTextBehavior 原生实现）；颜色/透明度渐变为 v3 同款。
        BasicTextBehavior on text {
            enabled: root.Style.animationEnabled
        }
        BasicColorBehavior on color {
            duration: root.Style.transitionDuration
            easing.type: Easing.InOutQuart
            enabled: root.Style.animationEnabled
        }
        BasicNumberBehavior on opacity {
            duration: root.Style.transitionDuration
            enabled: root.Style.animationEnabled
        }
    } //mainText

    // ===== 背景与反馈层 =====

    background: QoolBox {
        id: bgBox
        settings: root.backgroundSettings
        // v3 BasicButton 背景的最小按钮尺寸（CutCornerBox implicit 80x40）。
        implicitWidth: 80
        implicitHeight: 40
    }

    // 悬停底部渐变淡光（v3 Button 渐变覆盖层同款）。
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
        BasicNumberBehavior on opacity {
            duration: root.Style.movementDuration
            enabled: root.Style.animationEnabled
        }
    } //hoverGradient

    // 按下覆盖（v3 ControlPressedCover 的简化等效，见类文档）。
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
            cutSizes: root.bgSettings.cutSize
            fillColor: root.highlightColor
            borderWidth: 0
            curved: false
        }
        opacity: root.down ? 0.25 : 0
        z: 90
        BasicNumberBehavior on opacity {
            enabled: root.Style.animationEnabled
        }
    } //pressedCover

    // 禁用覆盖（v3 ControlLockedCover 的简化等效，见类文档）。
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
            cutSizes: root.bgSettings.cutSize
            fillColor: root.Style.negative
            borderWidth: 0
            curved: false
        }
        opacity: root.enabled ? 0 : 0.25
        z: 90
        BasicNumberBehavior on opacity {
            enabled: root.Style.animationEnabled
        }
    } //lockedCover

    // 标题加载器（v3 BasicButton.titleLoader 同款，默认不激活）。
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

    // 默认标题组件（v3 BasicText_ControlTitle 对位：装饰字号 + 占位符色）。
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

    // ===== 交互 =====

    onClicked: goForward()

    /*!
        \qmlmethod void CycleChoice::goForward()
        循环前进一项（counter.next()）。
    */
    function goForward() {
        counter.next()
    }

    /*!
        \qmlmethod void CycleChoice::goBackward()
        循环后退一项（counter.previous()）。
    */
    function goBackward() {
        counter.previous()
    }

    /*!
        \qmlmethod void CycleChoice::reset()
        复位到 defaultIndex（counter.reset()）。
    */
    function reset() {
        counter.reset()
    }

    // ===== 内部工具（v3 ComboChoiceModel::fetch_value / NumberLimiter 内联）=====

    // v3 fetch_value 的 int cycle：index 在 [0, length-1] 内原样返回，
    // 越界循环取模（-1 → 末项，length → 首项）；length <= 0 返回 -1。
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

    // 数组安全取值（空数组返回 undefined）。
    function _fetch(index, list) {
        const i = _cycle_index(index, list.length)
        if (i < 0 || i >= list.length)
            return undefined
        return list[i]
    }

    /*!
        \qmlmethod string CycleChoice::textAt(int index)
        循环取第 \c index 项文字（空 texts 返回空串）。
    */
    function textAt(index) {
        if (root.texts.length === 0)
            return ""
        return root.texts[_cycle_index(index, root.texts.length)]
    }

    /*!
        \qmlmethod var CycleChoice::valueAt(int index)
        循环取第 \c index 项 value；\c values 为空时退回 \c textAt()（v3 语义）。
    */
    function valueAt(index) {
        if (root.values.length === 0)
            return root.textAt(index)
        return _fetch(index, root.values)
    }

    /*!
        \qmlmethod color CycleChoice::colorAt(int index)
        循环取第 \c index 项颜色（空 colors 返回 undefined）。
    */
    function colorAt(index) {
        return _fetch(index, root.colors)
    }

    /*!
        \qmlmethod var CycleChoice::backgroundAt(int index)
        循环取第 \c index 项 background（空 backgrounds 返回 undefined）。
    */
    function backgroundAt(index) {
        return _fetch(index, root.backgrounds)
    }

    /*!
        \qmlmethod var CycleChoice::dataAt(int index)
        循环取第 \c index 项附加数据（空 datas 返回 undefined）。
    */
    function dataAt(index) {
        return _fetch(index, root.datas)
    }

    /*!
        \qmlmethod int CycleChoice::indexOfText(string value)
        返回 \c value 在 \c texts 中的下标，未找到或为空返回 -1。
    */
    function indexOfText(v) {
        return root.texts.indexOf(v)
    }

    /*!
        \qmlmethod int CycleChoice::indexOfValue(var value)
        返回 \c value 在 \c values 中的下标，未找到或为空返回 -1。
    */
    function indexOfValue(v) {
        return root.values.indexOf(v)
    }

    // 渲染文字：空文字/空数组 → fallbackText（v3 CycleChoiceText._get_text 语义）。
    function _get_text(index) {
        const t = root.textAt(index)
        return t === "" ? root.fallbackText : t
    }

    // 渲染颜色：空 colors → fallbackColor（v3 CycleChoiceText._get_color 语义）。
    function _get_color(index) {
        if (root.colors.length === 0)
            return root.fallbackColor
        return root.colors[_cycle_index(index, root.colors.length)]
    }

    // v3 NumberLimiter::keepBetweenEdges 的实数 cycle 逐字内联（x3_number_tools
    // 实数版：distance 不含 +1、末尾 -1 以包含最小值）。safeCurrentIndex 用它，
    // 语义与 v3 完全一致——数值上异于 int cycle 的边界是 v3 原行为，勿改。
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
        return lo + fixed - 1 // -1 以包含最小值（v3 注释原样）
    }
}
