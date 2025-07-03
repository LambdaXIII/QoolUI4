#ifndef QOOL_STYLEVALUEGROUP_H
#define QOOL_STYLEVALUEGROUP_H

#include "qool_theme_values_support.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/default_variant_map.hpp"
#include "qoolns.hpp"

#include <QBindable>
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class StyleValueGroup
  : public QObject
  , public ThemeValueGroupInterface {
  Q_OBJECT
  QML_ELEMENT
  QML_ANONYMOUS
public:
  explicit StyleValueGroup(QObject* parent = nullptr);
  virtual ~StyleValueGroup();

  Q_INVOKABLE bool contains(const QString& key) const override;
  Q_INVOKABLE QVariant value(
    const QString& key, const QVariant& defvalue = {}) const override;
  Q_INVOKABLE void setValue(const QString&, const QVariant&) override;
  Q_INVOKABLE void reset(const QString&) override;
  Q_INVOKABLE void reset() override;
  Q_INVOKABLE void setDefaults(const QVariantMap&) override;

  void inheritValues(StyleValueGroup* other);

  Q_SIGNAL void valueChanged(const QString& key);

protected:
  QVariantMap* m_intData;
  QVariantMap* m_extData;

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(
    StyleValueGroup, QVariantMap*, data)

}; // StyleValueGroup

QOOL_NS_END

#endif // QOOL_STYLEVALUEGROUP_H
