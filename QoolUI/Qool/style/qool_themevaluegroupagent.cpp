#include "qool_themevaluegroupagent.h"

QOOL_NS_BEGIN

ThemeValueGroupAgent::ThemeValueGroupAgent(QObject* parent)
  : QObject { parent } {
}

QVariant ThemeValueGroupAgent::value(
  const QString& key, const QVariant& defvalue) const {
  return m_data.value(key, defvalue);
}

void ThemeValueGroupAgent::setValue(
  const QString& key, const QVariant& value) {
  const auto old = m_data.value(key);
  if (old == value)
    return;
  m_data.set_value(key, value);
  when_value_changed({ key });
}

void ThemeValueGroupAgent::set_data(const QVariantMap& datas) {
  QStringList changed_keys;
  changed_keys.append(m_data.keys());
  m_data.setDefaults(datas);
  changed_keys.append(datas.keys());
  when_value_changed(changed_keys);
}

void ThemeValueGroupAgent::reset(const QString& key) {
  if (key.isEmpty())
    return;
  if (! m_data.contains(key))
    return;
  m_data.reset(key);
  when_value_changed({ key });
}

void ThemeValueGroupAgent::reset() {
  const QStringList changed_keys = m_data.currentKeys();
  if (changed_keys.isEmpty())
    return;
  m_data.reset();
  when_value_changed(changed_keys);
}

void ThemeValueGroupAgent::when_value_changed(const QStringList& keys) {
  const QSet<QString> _keys { keys.constBegin(), keys.constEnd() };
  Qt::beginPropertyUpdateGroup();
  for (const auto& key : _keys)
    emit valueChanged(key);
  Qt::endPropertyUpdateGroup();
}

QOOL_NS_END
