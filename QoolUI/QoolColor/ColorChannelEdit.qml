import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qool
import Qool.Controls
import Qool.Color

Control {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    property int channel: ColorNameHQ.HSLHue

    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }

    property real value

    // 归一化通道值解析：与 NumInput.parseChannelValue 语义一致（x > 1 → /1000、
    // 限幅 [0,1]、NaN 透传）——仓库数值输入刻意约定，勿改（见 NumInput 头注释）。
    function parseChannelValue(s) {
        let x = parseFloat(s);
        if (x > 1)
            x = x / 1000;
        if (x < 0)
            return 0;
        if (x > 1)
            return 1;
        return x;
    }

    contentItem: RowLayout {
        BasicControlText {
            text: ColorNameHQ.channelTag(root.channel)
            Layout.fillWidth: true
        }

        EditableText {
            id: editor
            animationEnabled: false

            // 输入格式校验（允许无前导零——显示格式 ".350" 可直接输入）：
            // 只验浮点格式、不设范围——范围/千分位语义由 parseChannelValue
            // 承担（x>1 → /1000、限幅 [0,1]）。validator 拒绝（空串/非法/
            // 科学计数法）→ 收尾 rejected：不写 text、不调 textFromEditText
            // → 显示保持真实源（自然回位）。用正则而非 DoubleValidator——
            // 后者受 locale 影响（接受分组符/阿拉伯数字，validate 依赖
            // locale 解析），本组件输入空间精确可控。
            validator: RegularExpressionValidator {
                regularExpression: /^[+-]?(\d+(\.\d*)?|\.\d+)$/
            }

            // 显示层覆写（EditableText displayItem 插拔设计意图——显示与
            // text 解耦）：显示真实源 format(proxy.value)，text 退化为纯
            // 保存形式（编辑基准 + 收尾提交目标）。文本手动同步（见
            // update_display——任何声明式绑定初始求值都早于 proxy 观察
            // 建立、冻结未就绪 NaN，实证），本组件不声明 text 绑定。
            displayItem: Text {
                font: editor.font
                color: editor.color
                horizontalAlignment: editor.horizontalAlignment
                verticalAlignment: editor.verticalAlignment
                anchors.fill: parent
                visible: opacity > 0
            }

            // 收尾转换（编辑结束、内容有变且通过 validator 时被调用）：
            // 解析 → 写 root.value（组件唯一写入口——链向下转发到
            // assistant），返回规范化串 format(解析值)——保存形式正确
            // （下次会话基准）；解析 NaN（防御——validator 已挡格式非法，
            // parseChannelValue 仍可能因未来 validator 移除/放宽透传 NaN）
            // → 不写数据、返回真实源当前值格式化（回位）。
            textFromEditText: function (s) {
                let v = root.parseChannelValue(s)
                if (Number.isNaN(v))
                    v = proxy.value
                else
                    root.value = v
                return ColorNameHQ.formatChannelNumberFloat(v)
            }
        }
    }//contentItem

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
    // 收尾写一次，parseChannelValue 限幅保证写入值=读回值，同值守卫收敛，
    // 不需要 _private ChannelSlider 的 userInteracting 互斥门控——那是 slider
    // 拖动每帧写值的防抖层，本组件无此场景）。
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
