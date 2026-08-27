#include "qool_colormapper.h"
#include "qoolcommon/math/utils.hpp"
#include <algorithm>

QOOL_NS_BEGIN

ColorMapper::ColorMapper(QObject* parent)
  : QObject{parent} {
  connect(this, &ColorMapper::modeChanged, this, &ColorMapper::updateRequested);

#define SETUP(N)                                          \
  connect(this, &ColorMapper::position##N##Changed, this, \
      &ColorMapper::color##N##Changed);                   \
  connect(this, &ColorMapper::updateRequested, this,      \
      &ColorMapper::color##N##Changed);

  QOOL_FOREACH_10(SETUP, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

#undef SETUP

  m_sortedStops.setUpdater([&] {
    auto stops = m_stops;
    std::stable_sort(
        stops.begin(), stops.end(), [](ColorMapperStop* a, ColorMapperStop* b) {
          return a->position() < b->position();
        });
    return stops;
  });
}

QColor ColorMapper::colorAt(qreal position) const {
  if (m_stops.isEmpty()) return Qt::white;
  if (m_stops.length() <= 1) return m_stops.constFirst()->color();

  auto stops = m_sortedStops.value();

  if (position < stops.constFirst()->position())
    return stops.constFirst()->color();
  if (position > stops.constLast()->position())
    return stops.constLast()->color();

  if (position == stops.constFirst()->position())
    return stops.constFirst()->color();
  if (position == stops.constLast()->position())
    return stops.constLast()->color();

  auto left = std::find_if(stops.crbegin(), stops.crend(),
      [&](ColorMapperStop* s) { return s->position() <= position; });
  if ((*left)->position() == position) return (*left)->color();

  auto right = std::find_if(stops.cbegin(), stops.cend(),
      [&](ColorMapperStop* s) { return s->position() >= position; });
  if ((*right)->position() == position) return (*right)->color();

  const auto p1 = (*left)->position();
  const auto p2 = (*right)->position();
  const auto a = math::remap<qreal>(
      position, p1, p2, (*left)->color().alphaF(), (*right)->color().alphaF());

#define CHANNEL(NAME)                                             \
  std::clamp(math::remap<qreal, qreal>(                           \
                 position, p1, p2, color1.NAME(), color2.NAME()), \
      0.0, 1.0)

  if (m_mode == RGB) {
    const auto color1 = (*left)->color().toRgb();
    const auto color2 = (*right)->color().toRgb();
    const auto r = CHANNEL(redF);
    const auto g = CHANNEL(greenF);
    const auto b = CHANNEL(blueF);
    return QColor::fromRgbF(r, g, b, a);
  }

  if (m_mode == HSL) {
    const auto color1 = (*left)->color().toHsl();
    const auto color2 = (*right)->color().toHsl();
    const auto h = CHANNEL(hslHueF);
    const auto s = CHANNEL(hslSaturationF);
    const auto l = CHANNEL(lightnessF);
    return QColor::fromHslF(h, s, l, a);
  }

  if (m_mode == CMYK) {
    const auto color1 = (*left)->color().toCmyk();
    const auto color2 = (*right)->color().toCmyk();
    const auto c = CHANNEL(cyanF);
    const auto m = CHANNEL(magentaF);
    const auto y = CHANNEL(yellowF);
    const auto k = CHANNEL(blackF);
    return QColor::fromCmykF(c, m, y, k, a);
  }

  const auto color1 = (*left)->color().toHsv();
  const auto color2 = (*right)->color().toHsv();
  const auto h = CHANNEL(hsvHueF);
  const auto s = CHANNEL(hsvSaturationF);
  const auto v = CHANNEL(valueF);
  return QColor::fromHsvF(h, s, v, a);

#undef CHANNEL
}

QQmlListProperty<ColorMapperStop> ColorMapper::stopList() {
  return {this, nullptr, __appendFunction, __countFunction, nullptr, nullptr,
    nullptr, __removeLastFunction};
}

void ColorMapper::__appendFunction(
    QQmlListProperty<ColorMapperStop>* property, ColorMapperStop* stop) {
  auto self = qobject_cast<ColorMapper*>(property->object);
  self->m_stops.append(stop);
  self->m_sortedStops.markDirty();
  connect(stop, &ColorMapperStop::positionChanged, self,
      &ColorMapper::updateRequested);
  connect(stop, &ColorMapperStop::positionChanged, self,
      [self] { self->m_sortedStops.markDirty(); });
  connect(stop, &ColorMapperStop::colorChanged, self,
      &ColorMapper::updateRequested);
  emit self->updateRequested();
}

void ColorMapper::__removeLastFunction(
    QQmlListProperty<ColorMapperStop>* property) {
  auto self = qobject_cast<ColorMapper*>(property->object);
  if (self->m_stops.isEmpty()) return;
  auto stop = self->m_stops.takeLast();
  self->disconnect(stop);
  self->m_sortedStops.markDirty();
  emit self->updateRequested();
}

qsizetype ColorMapper::__countFunction(
    QQmlListProperty<ColorMapperStop>* property) {
  auto self = qobject_cast<ColorMapper*>(property->object);
  return self->m_stops.length();
}

#define IMPL(N)                                                           \
  QColor ColorMapper::color##N() const { return colorAt(position##N()); }

QOOL_FOREACH_10(IMPL, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
#undef IMPL

QOOL_NS_END
