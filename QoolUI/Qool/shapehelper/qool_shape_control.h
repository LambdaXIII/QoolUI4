#ifndef QOOL_SHAPE_CONTROL_H
#define QOOL_SHAPE_CONTROL_H

#include "qool_smartobj.h"
#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include <QObject>

#include "qoolns.hpp"
#include <QBindable>
#include <QQmlEngine>
#include <QQuickItem>

QOOL_NS_BEGIN

class ShapeControl : public SmartObject {
  Q_OBJECT
  QML_ELEMENT
public:
  ShapeControl(QObject* parent = nullptr);
  virtual ~ShapeControl() = default;

  virtual Q_INVOKABLE bool contains(const QPointF& point) const;

  QQuickItem* target() const;
  void set_target(QQuickItem* newTarget);
  Q_SIGNAL void targetChanged();
  QBindable<QQuickItem*> bindable_target();

private:
  QQuickItem* m_target{nullptr};

  Q_PROPERTY(
      QQuickItem* target READ target WRITE set_target NOTIFY targetChanged)

#define DECL(T, N)                                                            \
public:                                                                       \
  T N() const;                                                                \
  void set_##N(const T& value);                                               \
  Q_SIGNAL void N##Changed();                                                 \
  QBindable<T> bindable_##N();                                                \
                                                                              \
private:                                                                      \
  Q_OBJECT_BINDABLE_PROPERTY(                                                 \
      ShapeControl, T, m_##N, &ShapeControl::N##Changed);                     \
  Q_PROPERTY(                                                                 \
      T N READ N WRITE set_##N NOTIFY N##Changed BINDABLE bindable_##N FINAL)

  DECL(QRectF, boundingRect)
#define __HANDLE__(N) DECL(qreal, N)

  QOOL_FOREACH_4(__HANDLE__, x, y, width, height)

#undef __HANDLE__
#undef DECL

#define DECL_R(T, N)                                                   \
public:                                                                \
  T N() const;                                                         \
  Q_SIGNAL void N##Changed();                                          \
  QBindable<T> bindable_##N();                                         \
                                                                       \
private:                                                               \
  Q_OBJECT_BINDABLE_PROPERTY(                                          \
      ShapeControl, T, m_##N, &ShapeControl::N##Changed);              \
  Q_PROPERTY(T N READ N NOTIFY N##Changed BINDABLE bindable_##N FINAL)

#define __HANDLE__(N) DECL(qreal, N)

  //   QOOL_FOREACH_5(
  //       __HANDLE__, aspectRatio, longEdge, shortEdge, halfWidth, halfHeight)

#undef __HANDLE__
#undef DECL_R
};

QOOL_NS_END

#endif // QOOL_SHAPE_CONTROL_H
