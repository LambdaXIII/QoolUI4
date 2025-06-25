#include "qool_theme_package.h"

QOOL_NS_BEGIN

ThemePackage::ThemePackage()
  : m_pData(new Data) {
}

ThemePackage::ThemePackage(const QVariantMap& active)
  : m_pData(new Data) {
  m_pData->active = active;
}

ThemePackage::ThemePackage(const QVariantMap& active,
  const QVariantMap& inactive, const QVariantMap& disabled)
  : m_pData(new Data) {
  m_pData->active = active;
  m_pData->inactive = inactive;
  m_pData->disabled = disabled;
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

const QVariantMap& ThemePackage::active() const {
  return m_pData->active;
}

const QVariantMap& ThemePackage::inactive() const {
  return m_pData->inactive;
}

const QVariantMap& ThemePackage::disabled() const {
  return m_pData->disabled;
}

QOOL_NS_END
