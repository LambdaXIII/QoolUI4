#ifndef QOOL_SHAPE_MACROS_H
#define QOOL_SHAPE_MACROS_H

#include "qoolcommon/qobject_property_macros.hpp"
#include <QBindable>

#define QOOL_DECL_POINT(NAME, ...)                               \
  QOBJECT_WRITABLE_PROPERTY_DECLARE(QPointF, NAME, __VA_ARGS__)  \
  QOBJECT_WRITABLE_PROPERTY_DECLARE(qreal, NAME##x, __VA_ARGS__) \
  QOBJECT_WRITABLE_PROPERTY_DECLARE(qreal, NAME##y, __VA_ARGS__) \
public:                                                          \
  QBindable<QPointF> bindable_##NAME();                          \
  QBindable<qreal> bindable_##NAME##x();                         \
  QBindable<qreal> bindable_##NAME##y();                         \
                                                                 \
private:                                                         \
  qreal m_##NAME##x, m_##NAME##y;

#define QOOL_IMPL_POINT(CLASS, NAME)                                 \
  QPointF CLASS::NAME() const { return {m_##NAME##x, m_##NAME##y}; } \
  qreal CLASS::NAME##x() const { return m_##NAME##x; }               \
  qreal CLASS::NAME##y() const { return m_##NAME##y; }               \
  QBindable<QPointF> CLASS::bindable_##NAME() {                      \
    return QBindable<QPointF>(this, "point" #NAME);                  \
  }                                                                  \
  QBindable<qreal> CLASS::bindable_##NAME##x() {                     \
    return QBindable<qreal>(this, "point" #NAME "x");                \
  }                                                                  \
  QBindable<qreal> CLASS::bindable_##NAME##y() {                     \
    return QBindable<qreal>(this, "point" #NAME "y");                \
  }                                                                  \
  void CLASS::set_##NAME##x(const qreal& v) {                        \
    if (m_##NAME##x == v) return;                                    \
    Qt::beginPropertyUpdateGroup();                                  \
    m_##NAME##x = v;                                                 \
    emit NAME##xChanged();                                           \
    emit NAME##Changed();                                            \
    Qt::endPropertyUpdateGroup();                                    \
  }                                                                  \
  void CLASS::set_##NAME##y(const qreal& v) {                        \
    if (m_##NAME##y == v) return;                                    \
    Qt::beginPropertyUpdateGroup();                                  \
    m_##NAME##y = v;                                                 \
    emit NAME##yChanged();                                           \
    emit NAME##Changed();                                            \
    Qt::endPropertyUpdateGroup();                                    \
  }                                                                  \
  void CLASS::set_##NAME(const QPointF& v) {                         \
    Qt::beginPropertyUpdateGroup();                                  \
    set_##NAME##x(v.x());                                            \
    set_##NAME##y(v.y());                                            \
    Qt::endPropertyUpdateGroup();                                    \
  }

#endif // QOOL_SHAPE_MACROS_H
