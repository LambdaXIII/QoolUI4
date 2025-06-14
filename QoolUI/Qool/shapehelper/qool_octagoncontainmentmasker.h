#ifndef QOOL_OCTAGONCONTAINMENTMASKER_H
#define QOOL_OCTAGONCONTAINMENTMASKER_H

#include "qool_octagonshapehelper.h"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolcommon/qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QQuickItem>

QOOL_NS_BEGIN

class OctagonContainmentMasker: public QQuickItem {
  Q_OBJECT
  QML_ELEMENT
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(
    OctagonShapeHelper*, shapeHelper, nullptr)
public:
  explicit OctagonContainmentMasker(QQuickItem* parent = nullptr);

  Q_INVOKABLE bool contains(const QPointF& point) const override;
};

QOOL_NS_END

#endif // QOOL_OCTAGONCONTAINMENTMASKER_H
