import QtQuick.Templates as T

// DialogButtonBox：T.DialogButtonBox 的特化换皮薄壳（ADR-0022 KD1）。
// 机制全部继承 Template 层；此处声明皮肤四件事（padding/spacing/delegate/
// 无 background）+ implicit 尺寸——Template 的 C++ contentItem 是裸 Item，
// 控件自尺寸由样式层计算（Basic 样式同此手法）：缺了它盒 implicit 尺寸
// 恒 0，QoolDialog 内容反推尺寸不含按钮排，footer 槽给出负宽度、按钮
// 不可见且布局互喂成 polish 循环。其余（background、alignment、文案）
// 一概不声明——对盒内已存在的按钮零干预。
T.DialogButtonBox {
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)
    padding: 0
    spacing: 4
    delegate: DialogButton {}
}
