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
 // 坐标策略由 contentItem.states 四态分派（orientation × mirrored 全组合，
 // PropertyChanges 无 target 写法）——勿回退嵌套三元手工绑定。
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

    // 竖直堆叠顺序（仅 orientation: Qt.Vertical 时有意义）：false（默认）
    // = 标签上/数字下；true = 数字上/标签下（贴滑块侧——ColorChannelControl
    // 竖直列用）。刻意用显式属性而**非 mirrored 驱动**：mirrored 是环境
    // 响应信号（RTL/LayoutMirroring 可继承），竖直行序是纯布局意图，
    // 不应随宿主环境翻动。
    property bool tagOnTop: false

    // 水平左右对调跟随 Control 内置只读 mirrored（LayoutMirroring 驱动，
    // 勿自声明——FINAL 属性覆写即编译错）：这是环境语义，保留。

    // 坐标策略 = 四态分派（orientation × mirrored 全组合，勿合并为三元
    // 表达式——嵌套三元曾静默吞行且不可读）。states 挂 contentItem；
    // PropertyChanges 无 target 写法，逐 id 寻址。
    contentItem: Item {
        id: contentBox

        // 隐式尺寸 = 活动方向的内容尺寸（普通 Item 不从子项派生隐式尺寸，
        // 显式算）。宿主按内容排布（如 ColorChannelControl 的 ColumnLayout）
        // 时据此定尺寸。
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
            horizontalAlignment: Text.AlignHCenter   // 竖直基准；水平由 state 覆盖
        }

        EditableText {
            id: editor
            objectName: "editor"
            animationEnabled: false
            // 编辑只读（root.readOnly 转发——不启动编辑会话；动画关闭同理）
            readOnly: root.readOnly
            // 编辑层字体与显示/标签统一（PixelFont.normal——编辑会话切换
            // 无字号跳动）
            font: PixelFont.normal

            // 输入格式校验（允许无前导零——显示格式 ".350" 可直接输入）：
            // 只验浮点格式、不设范围——范围/补点语义由
            // parseChannelNumberFloat 承担。validator 拒绝 → 收尾 rejected。
            validator: RegularExpressionValidator {
                regularExpression: /^[+-]?(\d+(\.\d*)?|\.\d+)$/
            }

            // 显示层覆写（EditableText displayItem 插拔设计）：显示真实源
            // format(proxy.value)。文字对齐随形态（水平贴数字框所贴的组件
            // 缘一侧、竖直框内居中）——displayItem 是 alias 子对象，
            // PropertyChanges 无法寻址，故此处保留唯一一处形态绑定。
            displayItem: ChannelNumText {
                horizontalAlignment: root.horizontal
                                     ? (root.mirrored ? Text.AlignLeft
                                                      : Text.AlignRight)
                                     : Text.AlignHCenter
            }

            // 收尾转换（编辑结束、内容有变且通过 validator 时被调用）：
            // 解析 → 写 root.value，返回规范化串 format(解析值)。
            textFromEditText: function (s) {
                let v = ColorNameHQ.parseChannelNumberFloat(s)
                if (Number.isNaN(v))
                    v = proxy.value
                else
                    root.value = v
                return ColorNameHQ.formatChannelNumberFloat(v)
            }

            // 数字框 4 字符锁宽（显示形态最长 '.xxx'；数值变化宽度稳定）
            width: textMetrics.advanceWidth("0000")
        }

        states: [
            // 水平：标签贴左缘左对齐 + 数字贴右缘右对齐，同行等高
            State {
                name: "hPlain"
                when: root.horizontal && !root.mirrored
                PropertyChanges {
                    tag.x: 0
                    tag.y: 0
                    tag.width: Math.max(0, contentBox.width - editor.width - 5)
                    tag.height: contentBox.height
                    tag.horizontalAlignment: Text.AlignLeft
                    editor.x: contentBox.width - editor.width
                    editor.y: 0
                    editor.height: contentBox.height
                }
            },
            // 水平镜像（RTL 页面全局镜像会波及水平布局——真实存在，勿删）
            State {
                name: "hMirrored"
                when: root.horizontal && root.mirrored
                PropertyChanges {
                    tag.x: contentBox.width - tag.width
                    tag.y: 0
                    tag.width: Math.max(0, contentBox.width - editor.width - 5)
                    tag.height: contentBox.height
                    tag.horizontalAlignment: Text.AlignRight
                    editor.x: 0
                    editor.y: 0
                    editor.height: contentBox.height
                }
            },
            // 竖直：短标签在上 + 数字在下，均水平居中
            State {
                name: "vPlain"
                when: root.vertical && !root.tagOnTop
                PropertyChanges {
                    tag.x: Math.max(0, (contentBox.width - tag.width) / 2)
                    tag.y: 0
                    tag.width: tag.implicitWidth
                    tag.height: tag.implicitHeight
                    editor.x: Math.max(0, (contentBox.width - editor.width) / 2)
                    editor.y: tag.height
                    editor.height: editor.displayItem.implicitHeight
                }
            },
            // 竖直翻转：数字在上 + 短标签在下（ColorChannelControl 竖直列
            // 的编辑行形态——数字贴近滑块侧）。由 tagOnTop 显式驱动，
            // 与环境镜像（mirrored）正交。
            State {
                name: "vFlipped"
                when: root.vertical && root.tagOnTop
                PropertyChanges {
                    tag.x: Math.max(0, (contentBox.width - tag.width) / 2)
                    tag.y: editor.height
                    tag.width: tag.implicitWidth
                    tag.height: tag.implicitHeight
                    editor.x: Math.max(0, (contentBox.width - editor.width) / 2)
                    editor.y: 0
                    editor.height: editor.displayItem.implicitHeight
                }
            }
        ]
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
