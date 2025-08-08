#ifndef QOOL_OCTAGONCONTAINMENTMASKER_H
#define QOOL_OCTAGONCONTAINMENTMASKER_H

#include "qool_qoolbox_shape_control.h"
#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QQuickItem>

QOOL_NS_BEGIN

class OctagonContainmentMasker : public QQuickItem {
  Q_OBJECT
  QML_ELEMENT
  QOBJECT_WRITABLE_PROPERTY(QoolBoxShapeControl*, shapeHelper, nullptr)
public:
  explicit OctagonContainmentMasker(QQuickItem* parent = nullptr);

  Q_INVOKABLE bool contains(const QPointF& point) const override;
};

QOOL_NS_END

#endif // QOOL_OCTAGONCONTAINMENTMASKER_H
