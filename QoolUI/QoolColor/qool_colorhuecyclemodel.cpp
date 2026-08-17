#include "qool_colorhuecyclemodel.h"

#include "qoolcommon/math/utils.hpp"

QOOL_NS_BEGIN

// 角色语义（color/hue/saturation/value/position）与变更语义见
// docs/reference/Qool.Color/ColorHueCycleModel.md。

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

// number：槽位数（行数）变化 → 整体模型重置。
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

// saturation：全行统一（dataChanged 只带 saturation、color 角色）。
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

// value：全行统一（dataChanged 只带 value、color 角色）。
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

// hueOffset：色相偏移（dataChanged 只带 hue、color 角色）。
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
