#include "qool_colorbank.h"

#include <algorithm>

QOOL_NS_BEGIN

/*!
    \qmltype ColorBank
    \inqmlmodule Qool.Color
    \nativetype qoolui::ColorBank
    \brief 无界稀疏的颜色索引容器（ColorBankPanel 的存储后端）。

    ColorBank 以整数索引（slot 编号）存取颜色。存储模型是**无界稀疏**
    的：只保留被 \l setColor() 显式写过的索引——写入 5 号槽不会创建
    0..4 号槽（QHash<int,QColor> 实现）。未设置的索引由 \l color()
    返回默认白色（Qt::white）。

    \section1 稀疏语义（刻意设计，勿改连续列表）

    存储是"写了什么才有什么"的稀疏映射：存 slot_5 不创建 1..4，
    存 slot_20 也不产生 0..19 的存储开销。索引无上界——不存在
    "最大槽数"概念，任何非负整数都可直接使用。

    这一模型刻意区别于"固定长度连续列表"（如 QList<QColor> 按长度
    预分配）：连续列表会把"面板显示范围"与"存储长度"强绑定——显示
    24 格就最多存 24 个，且必须为每个显示格维护占位值。本类型把
    显示（面板 slots 属性）与存储（无界稀疏映射）彻底解耦：显示
    范围只决定"面板画几格"，不决定"能存几个"。将来若有人把存储
    改成连续列表（QList/QVector 加长度上限），会同时引入显示范围
    边界与容量浪费两个回归——保持 QHash 稀疏映射。

    \section1 slots 是显示范围，不是存储边界

    \l ColorBankPanel 的 \c slots 属性（默认 24）只决定面板显示
    0..slots-1 号格。超出显示范围的索引照样可写入、可读取、可枚举：
    写 slot_20（slots=24 时在显示范围内）与写 slot_40（显示范围外）
    行为完全一致。范围外的值只是"不显示"，不是"丢失"——缩小 slots
    再放大不会丢数据。

    \section1 持久化刻意不做（宿主三接法）

    本类型**刻意不持久化**（v3 曾内置 QSettings 读写，v4 裁定去除）：
    组件库不承担存储格式、文件位置与用户数据生命周期。持久化需求由
    宿主从三接法中自选：

    \list
      \li 注入前构造填充（恢复）：宿主构造自己的 ColorBank 实例，
          按需逐个 \l setColor() 恢复旧数据，再注入给面板。
      \li 监听 \l colorChanged 纪录（保存）：连接 colorChanged(n)
          信号，每次变更同步写入宿主存储；配合 \l filledIndexes()
          与 \l color() 做启动时的批量恢复（读面）。
      \li 继承/仿写：子类化本类型（protected 的 m_colors 可直接访问）
          或在宿主侧仿写相同接口，把持久化逻辑内嵌。
    \endlist

    \section1 filledIndexes 的用途

    \l filledIndexes() 是宿主持久化的"读面"：返回所有已设置索引
    （升序、无重复），宿主据此批量导出（遍历 \l color() 写文件），
    或与自维护的索引清单对账。没有它，宿主只能另维护"哪些槽被写过"
    的清单，与本体数据分叉——本方法保证枚举与数据同源。

    \section1 相等守卫

    \l setColor() 带相等守卫：新旧值相等（QColor 全通道相等）时不写入、
    不发 \l colorChanged —— 与 v4 信号语义（Changed = 值实际变化才发）
    一致，避免宿主因重复写同一颜色而收到冗余通知。注意由此产生：
    显式写入默认白（Qt::white）到未设置槽位不触发信号（值未变）。

    \qmlsignal void ColorBank::colorChanged(int n)
    索引 \c n 的颜色值实际变化后发出（\l setColor() 相等守卫通过时）。
    值相同（含"未设置槽位写入白"）不发出。
*/
ColorBank::ColorBank(QObject* parent)
  : QObject { parent } {
}

/*!
    \qmlmethod color ColorBank::color(int n)
    返回索引 \c n 存储的颜色；未设置过时返回默认白色（Qt::white）。

    默认白返回值是刻意选择：面板未保存的格显示白色，无需宿主预填
    占位。注意"未设置"与"显式设置为白"在该返回值上无法区分——
    需要区分时用 \l filledIndexes() 判断索引是否已设置。
*/
QColor ColorBank::color(int n) const {
  return m_colors.value(n, Qt::white);
}

/*!
    \qmlmethod void ColorBank::setColor(int n, color)
    设置索引 \c n 的颜色为 \c color。

    带相等守卫：与当前值相等时不写入、不发 \l colorChanged。
    \c n 可为任意非负整数（无上界）；写入超出已设置范围的索引不会
    创建中间索引（稀疏，见类文档）。
*/
void ColorBank::setColor(int n, const QColor& color) {
  const auto old = m_colors.value(n, Qt::white);
  if (old == color)
    return;
  m_colors.insert(n, color);
  emit colorChanged(n);
}

/*!
    \qmlmethod list<int> ColorBank::filledIndexes()
    返回所有已设置索引的列表，升序排列、无重复。

    宿主持久化读面：配合 \l color() 批量导出（备份/导出场景）；
    恢复时也可先枚举再逐个写入。未设置任何颜色时返回空列表。
*/
QList<int> ColorBank::filledIndexes() const {
  QList<int> result;
  result.reserve(m_colors.size());
  for (auto it = m_colors.cbegin(); it != m_colors.cend(); ++it)
    result.append(it.key());
  std::sort(result.begin(), result.end());
  return result;
}

QOOL_NS_END
