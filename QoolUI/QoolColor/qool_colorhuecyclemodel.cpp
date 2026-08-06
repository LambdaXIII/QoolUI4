#include "qool_colorhuecyclemodel.h"

#include "qoolcommon/math/utils.hpp"

QOOL_NS_BEGIN

/*!
    \qmltype ColorHueCycleModel
    \inqmlmodule Qool.Color
    \nativetype qoolui::ColorHueCycleModel
    \brief 色相环等分循环模型：number 个等分槽位，每槽一个环上等距的颜色。

    供色相环类视图（如 HSVWheel）作为列表模型数据源使用。每个槽位
    （row）给出五个角色：color / hue / saturation / value / position。

    \section2 角色

    \table
    \header \li 角色 \li 类型 \li 含义
    \row \li color \li color \li 槽位颜色：QColor::fromHsvF(hue, saturation, value)
    \row \li hue \li real \li 循环折返后的色相（0..1）
    \row \li saturation \li real \li 当前饱和度（全行一致）
    \row \li value \li real \li 当前明度（全行一致）
    \row \li position \li real \li 槽位归一化位置（0..1）
    \endtable

    其中 position = row / number，hue = position + hueOffset（超出 0..1
    按模数循环折返，环状语义）。position / hue 的 0..1 归一化取值与
    ColorAssistant 的 hsvF 系列一致，可直接用于 QColor::fromHsvF 等
    浮点构造。

    \section2 变更语义

    \list
    \li \l number 变化：槽位数改变 → 整体模型重置
        （beginResetModel / endResetModel）；
    \li \l hueOffset 变化：全行 dataChanged（hue、color 角色）；
    \li \l saturation 变化：全行 dataChanged（saturation、color 角色）；
    \li \l value 变化：全行 dataChanged（value、color 角色）。
    \endlist
*/

/*!
    \qmlproperty int Qool.Color::ColorHueCycleModel::number
    \brief 等分槽位数（模型行数）。变化时整体重置模型。默认 16。
*/

/*!
    \qmlproperty real Qool.Color::ColorHueCycleModel::hueOffset
    \brief 色相偏移（0..1 归一化；超出区间自动循环折返）。默认 0。
*/

/*!
    \qmlproperty real Qool.Color::ColorHueCycleModel::saturation
    \brief 全行统一的饱和度（0..1）。默认 1。
*/

/*!
    \qmlproperty real Qool.Color::ColorHueCycleModel::value
    \brief 全行统一的明度（0..1）。默认 1。
*/

std::pair<qreal, qreal> ColorHueCycleModel::hue_and_position(
  int index) const {
  // v3 limit_number(int, cycle_limitation_tag) 的 v4 等价物：
  // math::cycle_in_range（模数回绕，非钳制）。槽位按环语义循环，
  // 越界 row 折回区间内，保证 position 恒在 [0, 1)。
  // 注：v3 泛型 cycle 实现带 -1 偏移缺陷——qreal 越界（如 hueOffset
  // 使 hue > 1）折回为负值，fromHsvF 得异常色；v4 以 cycle_in_range
  // 正确环折返（1.8 → 0.8）。
  const int cycled = math::cycle_in_range(0, index, m_number - 1);
  const qreal pos = qreal(cycled) / qreal(m_number);
  const qreal hue = math::cycle_in_range(0.0, pos + m_hueOffset, 1.0);
  return std::make_pair(hue, pos);
}

ColorHueCycleModel::ColorHueCycleModel(QObject* parent)
  : QAbstractListModel(parent) {
}

int ColorHueCycleModel::number() const {
  return m_number;
}

void ColorHueCycleModel::set_number(const int& new_number) {
  if (m_number == new_number)
    return;
  beginResetModel();
  m_number = new_number;
  endResetModel();
  emit numberChanged();
}

qreal ColorHueCycleModel::saturation() const {
  return m_saturation;
}

void ColorHueCycleModel::set_saturation(const qreal& new_saturation) {
  if (m_saturation == new_saturation)
    return;
  m_saturation = new_saturation;
  emit dataChanged(
    index(0, 0), index(m_number - 1, 0), { ColorRole, SaturationRole });
  emit saturationChanged();
}

qreal ColorHueCycleModel::value() const {
  return m_value;
}

void ColorHueCycleModel::set_value(const qreal& new_value) {
  if (m_value == new_value)
    return;
  m_value = new_value;
  emit dataChanged(
    index(0, 0), index(m_number - 1, 0), { ColorRole, ValueRole });
  emit valueChanged();
}

qreal ColorHueCycleModel::hueOffset() const {
  return m_hueOffset;
}

void ColorHueCycleModel::set_hueOffset(const qreal& new_hueOffset) {
  if (m_hueOffset == new_hueOffset)
    return;
  m_hueOffset = new_hueOffset;
  emit dataChanged(
    index(0, 0), index(m_number - 1, 0), { ColorRole, HueRole });
  emit hueOffsetChanged();
}

int ColorHueCycleModel::rowCount(const QModelIndex& parent) const {
  if (parent.isValid())
    return 0;
  return m_number;
}

QVariant ColorHueCycleModel::data(
  const QModelIndex& index, int role) const {
  if (!index.isValid())
    return {};

  if (role == SaturationRole)
    return m_saturation;
  if (role == ValueRole)
    return m_value;

  const auto x = hue_and_position(index.row());

  if (role == HueRole)
    return x.first;
  if (role == PositionRole)
    return x.second;
  if (role == ColorRole)
    return QColor::fromHsvF(x.first, m_saturation, m_value);

  return {};
}

QHash<int, QByteArray> ColorHueCycleModel::roleNames() const {
  return { { ColorRole, "color" }, { HueRole, "hue" },
    { SaturationRole, "saturation" }, { ValueRole, "value" },
    { PositionRole, "position" } };
}

QOOL_NS_END
