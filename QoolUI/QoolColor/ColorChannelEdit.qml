import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qool
import Qool.Controls
import Qool.Color
import "_private"

Control {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    property int channel: ColorNameHQ.HSLHue

    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }

    property real value

    contentItem: RowLayout {
        ChannelNumText {
            text: ColorNameHQ.channelTag(root.channel)
            color: Style.buttonText   // 标签语义（BasicControlText 原色）
            horizontalAlignment: Text.AlignLeft   // 标签左对齐（ChannelNumText 默认右对齐——display 用途）
            Layout.fillWidth: true
        }

        EditableText {
            id: editor
            animationEnabled: false
            // 编辑框宽度锁定 4 字符（FontMetrics——显示形态最长 '.xxx'；
            // 数值变化宽度稳定不跳动）
            Layout.preferredWidth: textMetrics.advanceWidth("0000")
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

            // 显示层覆写（EditableText displayItem 插拔设计意图——显示与
            // text 解耦）：显示真实源 format(proxy.value)，text 退化为纯
            // 保存形式（编辑基准 + 收尾提交目标）。文本手动同步（见
            // update_display——任何声明式绑定初始求值都早于 proxy 观察
            // 建立、冻结未就绪 NaN，实证），本组件不声明 text 绑定。
            // 字体统一（ChannelNumText——PixelFont.normal，与标签/编辑层
            // 同源）；几何由 EditableText 内 GeoLocker 统一锁定到内容
            // 容器（覆写者不声明几何）。
            displayItem: ChannelNumText {
            }

            // 收尾转换（编辑结束、内容有变且通过 validator 时被调用）：
            // 解析 → 写 root.value（组件唯一写入口——链向下转发到
            // assistant），返回规范化串 format(解析值)——保存形式正确
            // （下次会话基准）；解析 NaN（防御——validator 已挡格式非法，
            // 清洗解析仍可能因未来 validator 移除/放宽透传 NaN）→ 不写
            // 数据、返回真实源当前值格式化（回位）。解析走统一实现
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
        }
    }//contentItem

    // 编辑框宽度锁定的度量（4 字符宽——显示形态最长 '.xxx'；PixelFont
    // 等宽数字，取 4 个数字宽度覆盖全部形态）
    FontMetrics {
        id: textMetrics
        font: PixelFont.normal
    }

    // 通道寻址桥（动态属性名——channelNameF 为运行时字符串，QML 属性
    // 无法动态寻址）。target/property 为绑定、组件完成时才求值——任何
    // 声明式绑定（displayItem text、Binding 组件）的初始求值都早于 proxy
    // 观察建立，且 PropertyProxy 初始同步不发 valueChanged——声明式绑定
    // 冻结在未就绪 NaN（实证：初始显示 ".-648"；Binding 组件 when 恢复时
    // 依赖未变还会回放陈旧 NaN 缓存）。故显示与编辑基准一律手动同步
    // （update_display），不依赖引擎绑定求值序。
    PropertyProxy {
        id: proxy
        target: root.colorAssistant
        property: ColorNameHQ.channelNameF(root.channel)
    }

    // 显示与编辑基准的手动同步（确定性——不依赖引擎绑定求值序）：
    // - 显示：displayItem.text = format(proxy.value)——真实源直连，外部
    //   联动（assistant 通道变化）不经 text 中转。
    // - 编辑基准（非编辑态）：editor.text = format(proxy.value)——下次进
    //   编辑会话的基准为当前值（收尾值 = 规范化串 = 本值，同值不重复
    //   触发）；编辑态不写（用户输入优先，收尾自维护）。
    // 播种时机：onCompleted——此刻 proxy 已完成观察建立（completeCreate
    // 时 target/property 绑定求值 + 初始同步 read），getter 现读真实值。
    function update_display() {
        let s = ColorNameHQ.formatChannelNumberFloat(proxy.value)
        editor.displayItem.text = s
        if (!editor.editing)
            editor.text = s
    }

    // value ↔ assistant 双向同步（无条件——无拖动连续变化：文本编辑是离散
    // 收尾写一次，解析值=显示格式解析回读值（format/parse 配对），同值
    // 守卫收敛，不需要 _private ChannelSlider 的 userInteracting 互斥门控
    // ——那是 slider 拖动每帧写值的防抖层，本组件无此场景）。
    // 读取方向：assistant 通道 → proxy → root.value（外部改色/clamp 修正/联动）
    //   + 显示/基准刷新（update_display）。
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
