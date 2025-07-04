#ifndef QOOL_THEMEVALUEGROUPAGENT_H
#define QOOL_THEMEVALUEGROUPAGENT_H

#include "qool_theme.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/default_variant_map.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QReadWriteLock>
#include <QVariant>

QOOL_NS_BEGIN

class ThemeValueGroupAgent: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit ThemeValueGroupAgent(QObject* parent = nullptr);
  ~ThemeValueGroupAgent() = default;

  Q_INVOKABLE QVariant value(
    const QString& key, const QVariant& defvalue = {}) const;
  Q_INVOKABLE void setValue(const QString& key, const QVariant& value);

  void set_data(const QVariantMap& datas);

  Q_INVOKABLE void reset(const QString& key);
  Q_INVOKABLE void reset();

  Q_SIGNAL void valueChanged(QString);

  void inherit(ThemeValueGroupAgent* other);

protected:
  DefaultVariantMap m_data;
  void when_value_changed(const QStringList& keys = {});
};

QOOL_NS_END
#endif // QOOL_THEMEVALUEGROUPAGENT_H
