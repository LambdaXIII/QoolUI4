// NOTE(拍平件定位) v3 CycleChoiceButton 的拍平重写件，置于 Qool.Color/_private
// 而非 v4 Qool.Controls：暂不耦合 v4 Controls（拍平件只被 Color 模块内部消费），
// TODO(将来迁移): 待 Color 模块稳定后，本件扩展为完整控件迁移至 v4 Qool.Controls
// （届时 Color 切换依赖，废弃本私有版）——见 color-migration-spec §7-7。
// 迁入 Controls 时字号恢复 v3 buttonTextPixelSize（16px）语义（当前
// controlTextSize=12 为临时默认，模块内消费方均以 PixelFont.normal 覆盖，无可见影响）。
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

// 循环切换按钮拍平件（v3 `CycleChoiceButton` 全功能拍平）。
//
// 点击按钮在选项数组中循环前进（`goForward()`），提供 `goBackward()` /
// `reset()` 反向与复位；`currentIndex` 为当前选项下标，
// `displayText` / `displayColor` 为当前选项的文字与颜色。
//
// 数组属性（v3 ComboChoiceModel 取消，内联）
// v3 的 `ComboChoiceModel`（C++ QAbstractListModel）不再需要——数据面拍平为
// 数组属性：`texts`（必选，默认 `Style.papaWords`）、`colors`（默认
// [text, highlight]）、`values` / `backgrounds` / `datas`（可选扩展面，
// 默认空）。配套方法 `textAt()` / `valueAt()` / `colorAt()` /
// `backgroundAt()` / `dataAt()` / `indexOfText()` / `indexOfValue()`
// 与 v3 模型方法同名同语义；`length` 为 `texts` 长度。`currentData` 为
// `dataAt(currentIndex)`（`datas` 为空时返回 undefined，与 v3 空
// QVariant 语义等价）。
// 越界语义照迁：所有 `xxxAt()` 对下标做循环取模（v3
// `fetch_value` 的 int cycle），即下标 -1 取末项、length 取首项，永不越界。
//
// 循环/限幅逻辑（v3 IntegerCounter/NumberLimiter 内联）
// - `counter`（内部 QtObject）实现 v3 `IntegerCounter`：
//   `currentIndex` / `defaultIndex` 为别名；`keepIndexSafe` 为 true 时
//   计数采用 `JumpToOtherSide`（越过上界跳回最小值、越过下界跳回最大值），
//   false 时无限制（`NoLimits`，v3 默认）——此时 `currentIndex` 可越界，
//   由 `xxxAt()` 的循环取模兜底显示。
// - `safeCurrentIndex` 为 `NumberLimiter(CycleBetweenEdges)` 对
//   [`counter.min`, `counter.max + 1`] 的实数环绕结果（v3 原样，
//   含 x3_number_tools 实数版 cycle 的 `-1` 修正，见函数实现注释）——
//   注意它不是"裁剪到有效索引"的语义，是 v3 的逐字行为，勿当 bug 修。
// - `current` 初始为 `defaultValue` 的 QML 绑定（v3 同款写法）；首次
//   交互（next/previous/reset 写入）后绑定断开、独立变化——与 v3 一致。
// - 差异注明：v3 中直接写 `currentIndex` 会经 C++ setter 校验（按
//   counterBehavior 限幅）；拍平件中直接写 `currentIndex` 原样接受
//   （仅 next/previous 路径校验）。Color 模块无直接写 currentIndex 的
//   消费方，故行为不受影响。
//
// 交互反馈（v3 Control*Cover 的简化等效 + 临时件策略）
// 状态反馈即时到位、无过渡动画（临时件策略——动画已按裁定全部移除）。
// 保留以下状态渲染（纯状态绑定，无 Behavior）：
// - 按下 → 高亮色覆盖（`pressedCover`，opacity 0.25）
// - 禁用 → 负面色覆盖（`lockedCover`，opacity 0.25）+ 边框变负面色
// - 悬停/选中 → 边框高亮 + 底部渐变淡光
//
// showTitle 默认变更（与 v3 的刻意差异）
// v3 `CycleChoiceButton` 默认 `showTitle: true` 且继承占位标题
// `qsTr("酷酷的按钮")`，导致每个按钮右上角泄漏占位文字（遗留缺陷）。
// 拍平件保留 `showTitle` / `title` / `titleComponent` / `titleItem`
// 完整能力，默认 `showTitle: false`、`title: ""`——能力不降级，默认外观修正。
//
// 为什么在 Color/_private 而非 Controls
// 同 NumInput：暂不耦合 v4 Controls，TODO 将来迁移（见文件头注释）。
//
// 属性
// `texts` / `colors` 为数据面；`currentIndex` / `defaultIndex` /
// `safeCurrentIndex` / `keepIndexSafe` 为计数面；`displayText` /
// `displayColor` / `currentData` 为只读当前项；`highlightColor` 驱动
// 悬停/按下反馈（默认跟随 `displayColor`）；`fallbackText`（默认
// qsTr("<空>")，保持 v3 渲染行为——v3 的根 fallbackText 未参与渲染，
// 实际渲染用的是 CycleChoiceText 内层 "<空>"，拍平合并为单属性）/
// `fallbackColor` 为空数据兜底；`bgSettings`（v3 OctagonSettings API
// 对位：cutSize/strokeWidth/strokeColor/color）与 `backgroundSettings`
// （v4 惯例 QoolBoxSettings 对象，borderColor 受状态驱动）控制背景外观。

T.AbstractButton {
    id: root

    // 专项注释（缺陷修复）：v3 CycleChoiceButton 根为 Qool.Controls.Button
    // （implicit 尺寸自动取自 contentItem）；拍平件改根为 T.AbstractButton 后
    // 实测（Qt 6.11）Templates 不传播 contentItem implicit——implicit 恒 0，
    // ColorNameList 中无显式尺寸、分类切换器塌陷不可见。显式绑定回传
    // （contentItem 内 Text 自带 implicit 80x40，v3 BasicButton 最小按钮尺寸）。
    implicitWidth: contentItem.implicitWidth
    implicitHeight: contentItem.implicitHeight

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
    // cutSizes 便捷面删除迁移为四角显式（QoolColor/_private 不在兼容
    // 范围——便捷面删除后本组件仍须可编译）；四角绑定与原便捷面统一
    // 赋值等价。
    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        cutSizeTL: root.bgSettings.cutSize
        cutSizeTR: root.bgSettings.cutSize
        cutSizeBL: root.bgSettings.cutSize
        cutSizeBR: root.bgSettings.cutSize
        borderWidth: root.bgSettings.strokeWidth
        fillColor: root.bgSettings.color
        borderColor: root._feedbackBorderColor
        curved: false // v3 CutCornerBox 八边形外观
        // BasicColorBehavior on borderColor：动画已按临时件策略移除。
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

        // 动画已按临时件策略移除（文字弹跳/颜色渐变/透明度渐变），
        // 仅保留状态绑定——状态反馈即时到位。（v3 BasicText_ButtonContent → 删除）
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
        // BasicNumberBehavior on opacity：动画已按临时件策略移除。
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
            // cutSizes 便捷面删除迁移为四角显式（同 backgroundSettings 迁移说明）
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
        // BasicNumberBehavior on opacity：动画已按临时件策略移除。
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
            // cutSizes 便捷面删除迁移为四角显式（同 backgroundSettings 迁移说明）
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

    // 方法 goForward()：循环前进一项（counter.next()）。
    function goForward() {
        counter.next()
    }

    // 方法 goBackward()：循环后退一项（counter.previous()）。
    function goBackward() {
        counter.previous()
    }

    // 方法 reset()：复位到 defaultIndex（counter.reset()）。
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

    // 方法 textAt(index)：string：循环取第 `index` 项文字（空 texts 返回空串）。
    function textAt(index) {
        if (root.texts.length === 0)
            return ""
        return root.texts[_cycle_index(index, root.texts.length)]
    }

    // 方法 valueAt(index)：var：循环取第 `index` 项 value；`values` 为空时
    // 退回 `textAt()`（v3 语义）。
    function valueAt(index) {
        if (root.values.length === 0)
            return root.textAt(index)
        return _fetch(index, root.values)
    }

    // 方法 colorAt(index)：color：循环取第 `index` 项颜色（空 colors 返回 undefined）。
    function colorAt(index) {
        return _fetch(index, root.colors)
    }

    // 方法 backgroundAt(index)：var：循环取第 `index` 项 background
    // （空 backgrounds 返回 undefined）。
    function backgroundAt(index) {
        return _fetch(index, root.backgrounds)
    }

    // 方法 dataAt(index)：var：循环取第 `index` 项附加数据
    // （空 datas 返回 undefined）。
    function dataAt(index) {
        return _fetch(index, root.datas)
    }

    // 方法 indexOfText(value)：int：返回 `value` 在 `texts` 中的下标，
    // 未找到或为空返回 -1。
    function indexOfText(v) {
        return root.texts.indexOf(v)
    }

    // 方法 indexOfValue(value)：int：返回 `value` 在 `values` 中的下标，
    // 未找到或为空返回 -1。
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
