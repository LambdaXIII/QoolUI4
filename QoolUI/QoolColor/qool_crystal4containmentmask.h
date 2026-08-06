#ifndef QOOL_CRYSTAL4CONTAINMENTMASK_H
#define QOOL_CRYSTAL4CONTAINMENTMASK_H

#include "qoolns.hpp"

#include "qoolcommon/qobject_property_macros.hpp"

#include <QPointF>
#include <QQmlEngine>
#include <QQuickItem>

QOOL_NS_BEGIN

class Crystal4ContainmentMask : public QQuickItem {
  Q_OBJECT
  QML_ELEMENT

  QOBJECT_WRITABLE_PROPERTY_DECLARE(QPointF, centerPoint)

public:
  explicit Crystal4ContainmentMask(QQuickItem* parent = nullptr);

  bool contains(const QPointF& point) const override;

private:
  QPointF __transform(QPointF p) const;

  QPointF m_centerPoint{};
};

QOOL_NS_END

#endif // QOOL_CRYSTAL4CONTAINMENTMASK_H
