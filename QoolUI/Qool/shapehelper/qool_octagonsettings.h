#ifndef QOOL_OCTAGONSETTINGS_H
#define QOOL_OCTAGONSETTINGS_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolcommon/qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QObjectBindableProperty>
#include <QPointF>
#include <QQmlEngine>

QOOL_NS_BEGIN

class OctagonSettings: public QObject {
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(qreal cutSize READ cutSizeTL WRITE set_cutSizeTL NOTIFY
      cutSizeTLChanged)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, qreal, cutSizeTL)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, qreal, cutSizeTR)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, qreal, cutSizeBL)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, qreal, cutSizeBR)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QString, cutSizes)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, qreal, borderWidth)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, QColor, borderColor)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, QColor, fillColor)

public:
  explicit OctagonSettings(QObject* parent = nullptr);
  Q_INVOKABLE void dumpInfo() const;
};

QOOL_NS_END

#endif // QOOL_OCTAGONSETTINGS_H
