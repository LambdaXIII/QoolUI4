#ifndef QOOL_QOOLBOX_SETTINGS_H
#define QOOL_QOOLBOX_SETTINGS_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolcommon/qobject_property_macros.hpp"
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

  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, qreal, cutSizeTL)
  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, qreal, cutSizeTR)
  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, qreal, cutSizeBL)
  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, qreal, cutSizeBR)

  QOBJECT_WRITABLE_PROPERTY_DECLARE(QVariant, cutSizes)

  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, qreal, borderWidth)
  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, QColor, borderColor)
  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, QColor, fillColor)

  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, qreal, offsetX)
  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, qreal, offsetY)
  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, qreal, intOffsetX)
  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, qreal, intOffsetY)

  QBINDABLE_WRITABLE_PROPERTY(
    QoolBoxSettings, bool, curved)

  QBINDABLE_READONLY_PROPERTY(
    QoolBoxSettings, bool, isAllCutSizesEquals)
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_SETTINGS_H
