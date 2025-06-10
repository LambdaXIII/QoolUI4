#ifndef QOOL_SHAPEHELPER_H
#define QOOL_SHAPEHELPER_H

#include "qool_abstractshapehelper.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qoolns.hpp"

#include <QObject>
#include <QPointF>
#include <QQmlEngine>

QOOL_NS_BEGIN

class ShapeHelper: public AbstractShapeHelper {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit ShapeHelper(QObject* parent = nullptr);
  Q_INVOKABLE void dumpInfo() const override;

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    ShapeHelper, QPointF, boundingCenter)

#define DECL_POINT(NAME)                                               \
public:                                                                \
  Q_SIGNAL void point##NAME##Changed();                                \
  Q_SIGNAL void point##NAME##xChanged();                               \
  Q_SIGNAL void point##NAME##yChanged();                               \
  QPointF point##NAME() const;                                         \
  qreal point##NAME##x() const;                                        \
  qreal point##NAME##y() const;                                        \
  void set_point##NAME(const QPointF&);                                \
  void set_point##NAME##x(const qreal&);                               \
  void set_point##NAME##y(const qreal&);                               \
  QBindable<QPointF> bindable_point##NAME();                           \
  QBindable<qreal> bindable_point##NAME##x();                          \
  QBindable<qreal> bindable_point##NAME##y();                          \
                                                                       \
protected:                                                             \
  void __setup_point##NAME();                                          \
  Q_OBJECT_BINDABLE_PROPERTY(ShapeHelper, qreal, m_point##NAME##x,     \
    &ShapeHelper::point##NAME##xChanged)                               \
  Q_OBJECT_BINDABLE_PROPERTY(ShapeHelper, qreal, m_point##NAME##y,     \
    &ShapeHelper::point##NAME##yChanged)                               \
private:                                                               \
  Q_PROPERTY(QPointF point##NAME READ point##NAME WRITE                \
      set_point##NAME NOTIFY point##NAME##Changed)                     \
  Q_PROPERTY(                                                          \
    qreal point##NAME##x READ point##NAME##x WRITE set_point##NAME##x  \
      NOTIFY point##NAME##xChanged BINDABLE bindable_point##NAME##x)   \
  Q_PROPERTY(                                                          \
    qreal point##NAME##y READ point##NAME##y WRITE set_point##NAME##y  \
      NOTIFY point##NAME##yChanged BINDABLE bindable_point##NAME##y)

  QOOL_MACRO_FOREACH(DECL_POINT, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
  QOOL_MACRO_FOREACH(DECL_POINT, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19)
  QOOL_MACRO_FOREACH(DECL_POINT, 20, 21, 22, 23, 24)

  QOOL_MACRO_FOREACH(DECL_POINT, A, B, C, D, E, F, G, H, I, J, K, L, M,
    N, O, P, Q, R, S, T, U, V, W, X, Y, Z)

#undef DECL_POINT

private:
  void __setup_all_points();
};

QOOL_NS_END

#endif // QOOL_SHAPEHELPER_H
