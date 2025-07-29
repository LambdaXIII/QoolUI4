#ifndef QOOL_QOOLBOX_SETTINGS_H
#define QOOL_QOOLBOX_SETTINGS_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QObjectBindableProperty>
#include <QPointF>
#include <QQmlEngine>

QOOL_NS_BEGIN

class QoolBoxSettings: public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit QoolBoxSettings(QObject* parent = nullptr);
  Q_INVOKABLE void dumpInfo() const;

private:
  void set_sizes(qreal x);
  void set_sizes(qreal tl, qreal tr, qreal br, qreal bl);
  void set_sizes(const std::vector<std::optional<qreal>>& numbers);
  void set_sizes(const QVariantList& list);
  void set_sizes(const QString& x);
  void remove_cutSize_bindings();

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, qreal, cutSizeTL)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, qreal, cutSizeTR)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, qreal, cutSizeBL)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, qreal, cutSizeBR)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QVariant, cutSizes)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, qreal, borderWidth)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, QColor, borderColor)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, QColor, fillColor)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, qreal, offsetX)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, qreal, offsetY)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, qreal, intOffsetX)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, qreal, intOffsetY)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, bool, curved)

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    QoolBoxSettings, bool, isAllCutSizesEquals)
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_SETTINGS_H
