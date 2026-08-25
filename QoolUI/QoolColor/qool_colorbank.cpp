#include "qool_colorbank.h"
#include "qoolcommon/debug.hpp"
#include <QBindable>
#include <ranges>

QOOL_NS_BEGIN

ColorBank::ColorBank(QObject* parent)
  : QObject{parent} { }

QColor ColorBank::cellColor(int index) const {
  return m_colors.value(index, m_defaultColor);
}

void ColorBank::setCellColor(int i, const QColor& color) {
  if (color == cellColor(i)) return;

  const int old_cells = cells();
  const bool had_index = m_colors.contains(i);
  m_colors[i] = color;
  emit cellColorUpdated(i);
  if (! had_index) emit validCellIndexesChanged();
  if (cells() != old_cells) emit cellsChanged();

  xDebugQ << "Cell" << i << "set to" << color;
}

void ColorBank::eraseCellColor(int i) {
  if (! m_colors.contains(i)) return;
  const int old_cells = cells();
  m_colors.remove(i);
  emit cellColorUpdated(i);
  emit validCellIndexesChanged();
  if (cells() != old_cells) emit cellsChanged();
}

QList<QColor> ColorBank::cellColors() const {
  const auto count = cells();
  QList<QColor> result;
  for (int i = 0; i < count; ++i)
    result.append(m_colors.value(i, m_defaultColor));
  return result;
}

void ColorBank::setCellColors(const QList<QColor>& colors) {
  const QMap<int, QColor> old_map = m_colors;
  const auto old_indexes = old_map.keys();
  const int old_cells = cells();

  m_colors.clear();
  for (int i = 0; i < colors.length(); ++i) {
    const auto color = colors[i];
    if (color != m_defaultColor) m_colors.insert(i, colors[i]);
  }

  std::set<int> candidates{old_indexes.begin(), old_indexes.end()};
  for (int i = 0; i < colors.length(); ++i)
    candidates.insert(i);

  Qt::beginPropertyUpdateGroup();
  for (const int& x : candidates) {
    if (old_map.value(x, m_defaultColor) != m_colors.value(x, m_defaultColor))
      emit cellColorUpdated(x);
  }
  if (m_colors.keys() != old_indexes) emit validCellIndexesChanged();
  if (cells() != old_cells) emit cellsChanged();
  Qt::endPropertyUpdateGroup();
}

void ColorBank::clear() {
  if (m_colors.isEmpty()) return;

  const auto ks = m_colors.keys();
  const int old_cells = cells();

  m_colors.clear();

  Qt::beginPropertyUpdateGroup();
  for (const int& x : ks)
    emit cellColorUpdated(x);
  emit validCellIndexesChanged();
  if (cells() != old_cells) emit cellsChanged();
  Qt::endPropertyUpdateGroup();
}

std::set<int> ColorBank::empty_cell_indexes() const {
  const int count = cells();
  const auto keys = m_colors.keys();

  auto view = std::views::iota(0, count)
            | std::views::filter([&](int v) { return ! keys.contains(v); });

  std::set<int> result{view.begin(), view.end()};
  return result;
}

QColor ColorBank::defaultColor() const { return m_defaultColor; }

void ColorBank::set_defaultColor(const QColor& color) {
  if (color == m_defaultColor) return;

  m_defaultColor = color;

  const auto ks = empty_cell_indexes();
  Qt::beginPropertyUpdateGroup();
  emit defaultColorChanged();
  for (const int& x : ks)
    emit cellColorUpdated(x);
  Qt::endPropertyUpdateGroup();
}

int ColorBank::cells() const {
  const int len = (m_colors.empty() ? 0 : m_colors.lastKey()) + 1;
  return std::max(m_minimumCells, len);
}

QList<int> ColorBank::validCellIndexes() const { return m_colors.keys(); }

QOOL_NS_END
