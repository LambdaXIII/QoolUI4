#ifndef QOOL_ABSTRACTSHAPEHELPER_H
#define QOOL_ABSTRACTSHAPEHELPER_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQuickItem>

QOOL_NS_BEGIN

class AbstractShapeHelper: public QObject {
  Q_OBJECT

  QBINDABLE_WRITABLE_PROPERTY(
    AbstractShapeHelper, QQuickItem*, target)
  QBINDABLE_WRITABLE_PROPERTY(
    AbstractShapeHelper, qreal, width)
  QBINDABLE_WRITABLE_PROPERTY(
    AbstractShapeHelper, qreal, height)

  QBINDABLE_READONLY_PROPERTY(
    AbstractShapeHelper, qreal, shortEdge)
  QBINDABLE_READONLY_PROPERTY(
    AbstractShapeHelper, qreal, longEdge)
  QBINDABLE_READONLY_PROPERTY(
    AbstractShapeHelper, qreal, widthHeightRatio)
  QBINDABLE_READONLY_PROPERTY(
    AbstractShapeHelper, qreal, halfWidth)
  QBINDABLE_READONLY_PROPERTY(
    AbstractShapeHelper, qreal, halfHeight)

public:
  explicit AbstractShapeHelper(QObject* parent = nullptr);
  virtual ~AbstractShapeHelper() = default;

  virtual Q_INVOKABLE bool contains(const QPointF& point) const;
  virtual Q_INVOKABLE void dumpInfo() const;

private:
  Q_SLOT void resetSizeBindings();
};

QOOL_NS_END

#endif // QOOL_ABSTRACTSHAPEHELPER_H
