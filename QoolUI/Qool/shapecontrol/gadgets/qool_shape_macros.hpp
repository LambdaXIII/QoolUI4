#ifndef QOOL_SHAPE_MACROS_H
#define QOOL_SHAPE_MACROS_H

#include "qoolcommon/qobject_property_macros.hpp"
#include <QBindable>

#define QOOL_DECL_POINT(NAME, ...)                                      \
  QOBJECT_WRITABLE_PROPERTY_DECLARE(QPointF, point##NAME, __VA_ARGS__)  \
  QOBJECT_WRITABLE_PROPERTY_DECLARE(qreal, point##NAME##x, __VA_ARGS__) \
  QOBJECT_WRITABLE_PROPERTY_DECLARE(qreal, point##NAME##y, __VA_ARGS__) \
public:                                                                 \
  QBindable<QPointF> bindable_point##NAME();                            \
  QBindable<qreal> bindable_point##NAME##x();                           \
  QBindable<qreal> bindable_point##NAME##y();                           \
                                                                        \
private:                                                                \
  qreal m_point##NAME##x, m_point##NAME##y;

#define QOOL_IMPL_POINT(CLASS, NAME)                               \
  QPointF CLASS::point##NAME() const {                             \
    return {m_point##NAME##x, m_point##NAME##y};                   \
  }                                                                \
  qreal CLASS::point##NAME##x() const { return m_point##NAME##x; } \
  qreal CLASS::point##NAME##y() const { return m_point##NAME##y; } \
  QBindable<QPointF> CLASS::bindable_point##NAME() {               \
    return QBindable<QPointF>(this, "point" #NAME);                \
  }                                                                \
  QBindable<qreal> CLASS::bindable_point##NAME##x() {              \
    return QBindable<qreal>(this, "point" #NAME "x");              \
  }                                                                \
  QBindable<qreal> CLASS::bindable_point##NAME##y() {              \
    return QBindable<qreal>(this, "point" #NAME "y");              \
  }                                                                \
  void CLASS::set_point##NAME##x(const qreal& v) {                 \
    if (m_point##NAME##x == v) return;                             \
    Qt::beginPropertyUpdateGroup();                                \
    m_point##NAME##x = v;                                          \
    emit point##NAME##xChanged();                                  \
    emit point##NAME##Changed();                                   \
    Qt::endPropertyUpdateGroup();                                  \
  }                                                                \
  void CLASS::set_point##NAME##y(const qreal& v) {                 \
    if (m_point##NAME##y == v) return;                             \
    Qt::beginPropertyUpdateGroup();                                \
    m_point##NAME##y = v;                                          \
    emit point##NAME##yChanged();                                  \
    emit point##NAME##Changed();                                   \
    Qt::endPropertyUpdateGroup();                                  \
  }                                                                \
  void CLASS::set_point##NAME(const QPointF& v) {                  \
    Qt::beginPropertyUpdateGroup();                                \
    set_point##NAME##x(v.x());                                     \
    set_point##NAME##y(v.y());                                     \
    Qt::endPropertyUpdateGroup();                                  \
  }

#endif // QOOL_SHAPE_MACROS_H
