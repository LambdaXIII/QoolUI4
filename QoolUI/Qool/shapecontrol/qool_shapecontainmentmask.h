#ifndef QOOL_SHAPECONTAINMENTMASK_H
#define QOOL_SHAPECONTAINMENTMASK_H

#include "qool_shapecontrol.h"

#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolns.hpp"

#include <QQmlEngine>
#include <QQuickItem>

QOOL_NS_BEGIN

class ShapeContainmentMask : public QQuickItem {
  Q_OBJECT
  QML_ELEMENT

  QOBJECT_WRITABLE_PROPERTY_DECLARE(ShapeControl*, control)

public:
  explicit ShapeContainmentMask(QQuickItem* parent = nullptr);
  bool contains(const QPointF& point) const override;

private:
  ShapeControl* m_control = nullptr;
};

QOOL_NS_END

#endif // QOOL_SHAPECONTAINMENTMASK_H
