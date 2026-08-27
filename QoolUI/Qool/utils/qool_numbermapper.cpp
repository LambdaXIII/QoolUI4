#include "qool_numbermapper.h"
#include "qoolcommon/math/utils.hpp"

QOOL_NS_BEGIN

NumberMapperStop::NumberMapperStop(QObject* parent)
  : QObject(parent) {
}

NumberMapper::NumberMapper(QObject* parent)
  : QObject{parent} {
#define SETUP(N)                                           \
  connect(this, &NumberMapper::position##N##Changed, this, \
      &NumberMapper::value##N##Changed);                   \
  connect(this, &NumberMapper::stopsChanged, this,         \
      &NumberMapper::value##N##Changed);

  QOOL_FOREACH_10(SETUP, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

#undef SETUP

  m_sortedStops.setUpdater([&] {
    auto stops = m_stops;
    std::stable_sort(stops.begin(), stops.end(),
        [](NumberMapperStop* s1, NumberMapperStop* s2) {
          return s1->position() < s2->position();
        });
    return stops;
  });
}

qreal NumberMapper::valueAt(qreal position) const {
  if (m_stops.isEmpty()) return 0;
  if (m_stops.length() <= 1) return m_stops.constFirst()->value();

  auto stops = m_sortedStops.value();

  if (position < stops.constFirst()->position())
    return stops.constFirst()->value();

  if (position > stops.constLast()->position())
    return stops.constLast()->value();

  auto left = std::find_if(stops.crbegin(), stops.crend(),
      [&](NumberMapperStop* stop) { return stop->position() <= position; });

  if ((*left)->position() == position) return (*left)->value();

  auto right = std::find_if(stops.cbegin(), stops.cend(),
      [&](NumberMapperStop* stop) { return stop->position() >= position; });

  if ((*right)->position() == position) return (*right)->value();

  return math::remap(position, (*left)->position(), (*right)->position(),
      (*left)->value(), (*right)->value());
}

QQmlListProperty<NumberMapperStop> NumberMapper::stopList() {
  return {this, nullptr, __appendFunction, __countFunction, nullptr, nullptr,
    nullptr, __removeLastFunction};
}

void NumberMapper::__appendFunction(
    QQmlListProperty<NumberMapperStop>* property, NumberMapperStop* stop) {
  auto self = qobject_cast<NumberMapper*>(property->object);
  connect(stop, &NumberMapperStop::positionChanged, self,
      &NumberMapper::stopsChanged);
  connect(stop, &NumberMapperStop::positionChanged, self,
      [self] { self->m_sortedStops.markDirty(); });
  connect(
      stop, &NumberMapperStop::valueChanged, self, &NumberMapper::stopsChanged);
  self->m_stops.append(stop);
  self->m_sortedStops.markDirty();
  emit self->stopsChanged();
}

void NumberMapper::__removeLastFunction(
    QQmlListProperty<NumberMapperStop>* property) {
  auto self = qobject_cast<NumberMapper*>(property->object);
  if (self->m_stops.isEmpty()) return;
  auto stop = self->m_stops.takeLast();
  self->disconnect(stop);
  self->m_sortedStops.markDirty();
  emit self->stopsChanged();
}

qsizetype NumberMapper::__countFunction(
    QQmlListProperty<NumberMapperStop>* property) {
  auto self = qobject_cast<NumberMapper*>(property->object);
  return self->m_stops.length();
}

#define IMPL(N)                                                           \
  qreal NumberMapper::value##N() const { return valueAt(position##N()); }

QOOL_FOREACH_10(IMPL, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
#undef IMPL

QOOL_NS_END
