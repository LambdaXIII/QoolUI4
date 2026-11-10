import QtQuick.Controls.Basic as Basic

// DialogButtonBox：样式层 DialogButtonBox 的皮肤特化（ADR-0022 KD1）。
//
// 基座必须取样式层的 DialogButtonBox，不能取 QtQuick.Templates 的
// DialogButtonBox：Template 层只有算法（实例化、role 分发、平台排序、默认
// 按钮），**内容宿主 contentItem 与按钮排布在样式层**。只继承 Template 时
// standardButtons 照样实例化、implicit 尺寸也照算，但按钮没有父件，永不进入
// 场景图——count/implicit 全对，屏幕上什么都没有。
//
// 基座锚死 Basic 风格（而非随应用风格变化）：皮肤四件事全部覆写，
// 平台风格只影响内部宿主形态，锚死才有确定行为，且只依赖 Qt 必装的 Basic 插件。
//
// 皮肤四件事：padding 0（盒外间距归 DialogSurface 槽位）/ spacing 4 /
// 无 background（盒子在表面件底上天然透明）/ delegate: DialogButton。
Basic.DialogButtonBox {
    padding: 0
    spacing: 4
    background: null
    delegate: DialogButton {}
}
