#ifndef QOOL_OCTAGONSETTINGS_H
#define QOOL_OCTAGONSETTINGS_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QObjectBindableProperty>
#include <QPointF>
#include <QQmlEngine>

QOOL_NS_BEGIN

class OctagonSettings: public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit OctagonSettings(QObject* parent = nullptr);
  Q_INVOKABLE void dumpInfo() const;

private:
  std::array<qreal, 4> m_cutSizes;
  bool m_cutSizesLocked { false };
  Q_SLOT void notify_all_cutSizes_changed();
  void set_sizes(qreal x);
  void set_sizes(qreal tl, qreal tr, qreal br, qreal bl);
  void set_sizes(const std::vector<std::optional<qreal>>& numbers);
  void set_sizes(const QVariantList& list);
  void set_sizes(const QString& x);

  Q_PROPERTY(qreal cutSize READ cutSizeTL WRITE set_cutSizeTL NOTIFY
      cutSizeTLChanged)

#define DECL(N)                                                        \
public:                                                                \
  qreal cutSize##N() const;                                            \
  void set_cutSize##N(qreal x);                                        \
  Q_SIGNAL void cutSize##N##Changed();                                 \
  QBindable<qreal> bindable_cutSize##N();                              \
                                                                       \
private:                                                               \
  Q_PROPERTY(qreal cutSize##N READ cutSize##N WRITE                    \
      set_cutSize##N NOTIFY cutSize##N##Changed)

  QOOL_FOREACH_4(DECL, TL, TR, BL, BR)

#undef DECL

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QVariant, cutSizes)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(bool, cutSizesLocked)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, qreal, borderWidth)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, QColor, borderColor)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, QColor, fillColor)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, qreal, offsetX)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, qreal, offsetY)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, qreal, intOffsetX)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonSettings, qreal, intOffsetY)
};

QOOL_NS_END

#endif // QOOL_OCTAGONSETTINGS_H
