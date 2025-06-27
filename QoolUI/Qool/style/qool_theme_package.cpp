#include "qool_theme_package.h"

#include <QUuid>

QOOL_NS_BEGIN

ThemePackage::ThemePackage()
  : m_pData(new Data) {
}

ThemePackage::ThemePackage(
  const QString& name, const QVariantMap& active)
  : m_pData(new Data) {
  if (! name.isEmpty())
    m_pData->name = name;
  m_pData->active = active;
}

ThemePackage::ThemePackage(const QString& name,
  const QVariantMap& active, const QVariantMap& inactive,
  const QVariantMap& disabled, const QVariantMap& metadata)
  : m_pData(new Data) {
  if (! name.isEmpty())
    m_pData->name = name;
  m_pData->active = active;
  m_pData->inactive = inactive;
  m_pData->disabled = disabled;
  m_pData->metadata = metadata;
}

ThemePackage::ThemePackage(const ThemePackage& other)
  : m_pData(other.m_pData) {
}

QVariant ThemePackage::activeValue(
  const QString& key, const QVariant& defaultValue) const {
  return m_pData->active.value(key, defaultValue);
}

QVariant ThemePackage::inactiveValue(
  const QString& key, const QVariant& defaultValue) const {
  if (m_pData->inactive.contains(key))
    return m_pData->inactive.value(key);
  return m_pData->active.value(key, defaultValue);
}

QVariant ThemePackage::disabledValue(
  const QString& key, const QVariant& defaultValue) const {
  if (m_pData->disabled.contains(key))
    return m_pData->disabled.value(key);
  return m_pData->active.value(key, defaultValue);
}

bool ThemePackage::contains(const QString& key) const {
  return m_pData->metadata.contains(key)
         || m_pData->active.contains(key);
}

QVariant ThemePackage::value(
  const QString& key, const QVariant& defaultValue) const {
  if (m_pData->active.contains(key))
    return m_pData->active.value(key);
  return m_pData->metadata.value(key, defaultValue);
}

QVariant ThemePackage::data(
  const QString& key, const QVariant& defaultValue) const {
  return m_pData->metadata.value(key, defaultValue);
}

QVariantMap ThemePackage::active() const {
  return m_pData->active;
}

QVariantMap ThemePackage::inactive() const {
  auto result = m_pData->active;
  result.insert(m_pData->inactive);
  return result;
}

QVariantMap ThemePackage::disabled() const {
  auto result = m_pData->active;
  result.insert(m_pData->disabled);
  return result;
}

QVariantMap ThemePackage::metadata() const {
  return m_pData->metadata;
}

QString ThemePackage::name() const {
  if (m_pData->metadata.contains("name"))
    return m_pData->metadata.value("name").toString();
  return m_pData->name;
}

QOOL_NS_END
