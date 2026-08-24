import QtQuick
import QtQuick.Controls.Basic
import Qool
import Qool.Controls
import Qool.Color
import "_private"

// 单通道值编辑控件：通道标签 + 数字框（EditableText 编辑会话）。
// orientation 双布局——水平（默认）：长标签 channelTag 贴左 + 数字贴右；
// 竖直：短标签 channelTagShort 在上 + 数字在下、水平居中。
// mirrored 镜像（Control 内置只读属性，LayoutMirroring.enabled 驱动，
// 与 ColorChannelSlider 消费 T.Slider 的方式同构）——只换元素位置：
// 水平左右对调（间隙不变）、竖直上下对调；文字方向与对齐不受影响。
// 布局为手工绑定（内容固定——标签 + 数字框，布局引擎的动态排布价值用不上；
// 直接绑定坐标/尺寸，同步、单层、无中间布局容器）。
Control {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    property int channel: ColorNameHQ.HSLHue

    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }

    property real value

    // 编辑只读（TextField 惯例命名，转发 → EditableText.readOnly：不启动
    // 编辑会话——点击/聚焦空转；组合件 ColorChannelControl 经本属性转发
    // 外壳 readOnly，宿主亦可直接设）。
    property bool readOnly: false

    // 布局方向（int 承载 Qt 枚举值）。派生只读 horizontal/vertical 驱动
    // 标签文字与坐标/尺寸绑定分派。
    property int orientation: Qt.Horizontal
    readonly property bool horizontal: orientation === Qt.Horizontal
    readonly property bool vertical: orientation === Qt.Vertical

    // 镜像响应 Control 内置只读 mirrored（LayoutMirroring 驱动，勿再自
    // 声明——FINAL 属性覆写即编译错）。坐标绑定按下述取反：
    // 水平——tag 贴右、editor 贴左（间隙 5px 不变）；
    // 竖直——editor 在上、tag 在下（水平居中不变）。

    contentItem: Item {
        // 隐式尺寸 = 活动方向的内容尺寸（普通 Item 不从子项派生隐式尺寸，
        // 显式算；tag/editor 的隐式尺寸同步可得，无布局 polish 依赖）。
        // 宿主按内容排布（如 ColorChannelControl 的 ColumnLayout）时据此定
        // 尺寸。数字框维度用锁宽（editor.width）——与原 RowLayout 的
        // preferredWidth 行为一致。
        implicitWidth: root.horizontal ? tag.implicitWidth + editor.width + 5
                                       : Math.max(tag.implicitWidth, editor.width)
        implicitHeight: root.horizontal ? Math.max(tag.implicitHeight, editor.implicitHeight)
                                        : tag.implicitHeight + editor.implicitHeight

        ChannelNumText {
            id: tag
            objectName: "tag"
            text: root.vertical ? ColorNameHQ.channelTagShort(root.channel)
                                : ColorNameHQ.channelTag(root.channel)
            color: Style.buttonText   // 标签语义（BasicControlText 原色）
            // 水平：贴左（mirrored 贴右——x = parent.width - width，
            // 因 width 撑满剩余，右缘即贴边）/ 竖直水平居中
            // （ChannelNumText 默认右对齐——display 用途）
            x: root.horizontal ? (root.mirrored ? parent.width - width : 0)
                               : Math.max(0, (parent.width - width) / 2)
            y: !root.horizontal && root.mirrored ? editor.height : 0
            // 水平撑满剩余（留 5px 间隙贴数字框）/ 竖直自然宽
            width: root.horizontal ? Math.max(0, parent.width - editor.width - 5) : implicitWidth
            height: root.horizontal ? parent.height : implicitHeight
        }

        EditableText {
            id: editor
            objectName: "editor"
            animationEnabled: false
            // 编辑只读（root.readOnly 转发——不启动编辑会话；动画关闭同理）
            readOnly: root.readOnly
            // 编辑层字体与显示/标签统一（PixelFont.normal——覆盖 EditableText
            // 默认 controlTextSize，编辑会话切换无字号跳动）
            font: PixelFont.normal

            // 输入格式校验（允许无前导零——显示格式 ".350" 可直接输入）：
            // 只验浮点格式、不设范围——范围/补点语义由
            // parseChannelNumberFloat 承担（无点头部补点、NaN 透传）。
            // validator 拒绝（空串/非法/科学计数法）→ 收尾 rejected：不写
            // text、不调 textFromEditText → 显示保持真实源（自然回位）。
            // 用正则而非 DoubleValidator——后者受 locale 影响（接受分组符/
            // 阿拉伯数字，validate 依赖 locale 解析），本组件输入空间精确
            // 可控。
            validator: RegularExpressionValidator {
                regularExpression: /^[+-]?(\d+(\.\d*)?|\.\d+)$/
            }

            // 显示层覆写（EditableText displayItem 插拔设计——显示与 text
            // 解耦）：显示真实源 format(proxy.value)，text 退化为纯保存形式
            // （编辑基准 + 收尾提交目标）。文本手动同步（update_display——
            // 声明式绑定初始求值早于 proxy 观察建立，本组件不声明 text 绑定）。
            // 几何由 EditableText 内 GeoLocker 统一锁定，覆写者不声明几何。
            displayItem: ChannelNumText {
            }

            // 收尾转换（编辑结束、内容有变且通过 validator 时被调用）：
            // 解析 → 写 root.value（组件唯一写入口——链向下转发到
            // assistant），返回规范化串 format(解析值)（下次会话基准）；
            // 解析 NaN（防御——validator 已挡格式非法）→ 不写数据、返回
            // 真实源当前值格式化（回位）。解析走统一实现
            // ColorNameHQ.parseChannelNumberFloat（清洗+补点，与
            // formatChannelNumberFloat 配对）。
            textFromEditText: function (s) {
                let v = ColorNameHQ.parseChannelNumberFloat(s)
                if (Number.isNaN(v))
                    v = proxy.value
                else
                    root.value = v
                return ColorNameHQ.formatChannelNumberFloat(v)
            }

            // 数字框 4 字符锁宽（显示形态最长 '.xxx'；数值变化宽度稳定不跳
            // 动）。水平贴右（mirrored 贴左）、竖直水平居中、堆在标签下方
            // （mirrored 翻到标签上方）。
            width: textMetrics.advanceWidth("0000")
            height: root.horizontal ? parent.height : implicitHeight
            x: root.horizontal ? (root.mirrored ? 0 : parent.width - width)
                               : Math.max(0, (parent.width - width) / 2)
            y: !root.horizontal && root.mirrored ? 0 : tag.height
        }
    }//contentItem

    // 编辑框宽度锁定的度量（4 字符宽——显示形态最长 '.xxx'；PixelFont
    // 等宽数字，取 4 个数字宽度覆盖全部形态）
    FontMetrics {
        id: textMetrics
        font: PixelFont.normal
    }

    // 通道寻址桥（动态属性名——channelNameF 为运行时字符串，QML 属性
    // 无法动态寻址）。
    PropertyProxy {
        id: proxy
        target: root.colorAssistant
        property: ColorNameHQ.channelNameF(root.channel)
    }

    // 显示与编辑基准的手动同步（声明式绑定初始求值早于 proxy 观察建立，
    // 故不依赖引擎绑定求值序，一律手动）：
    // - 显示：displayItem.text = format(proxy.value)——真实源直连，外部
    //   联动（assistant 通道变化）不经 text 中转。
    // - 编辑基准（非编辑态）：editor.text = format(proxy.value)——下次进
    //   编辑会话的基准为当前值；编辑态不写（用户输入优先，收尾自维护）。
    // 播种时机：onCompleted——此刻 proxy 已完成观察建立，getter 现读真实值。
    function update_display() {
        let s = ColorNameHQ.formatChannelNumberFloat(proxy.value)
        editor.displayItem.text = s
        if (!editor.editing)
            editor.text = s
    }

    // value ↔ assistant 双向同步（无条件——文本编辑是离散收尾写一次，
    // 同值守卫收敛，无需 slider 族的 userInteracting 互斥门控——那是
    // 拖动每帧写值的防抖层，本组件无此场景）。
    // 读取方向：assistant 通道 → proxy → root.value（外部改色/clamp 修正/
    // 联动）+ 显示/基准刷新（update_display）。
    // 写入方向：编辑收尾 / 外部程序 → root.value → proxy → assistant 通道。
    Connections {
        target: proxy
        function onValueChanged() {
            root.value = proxy.value;
            update_display()
        }
    }
    Connections {
        target: root
        function onValueChanged() {
            proxy.value = root.value
        }
    }

    Component.onCompleted: update_display()
}
