#include "qool_xml_theme_loader.h"

#include "qool_xml_theme_loader_impl.h"
#include "qoolcommon/debug.hpp"

#include <QColor>
#include <QFileInfo>

QOOL_NS_BEGIN

XMLThemeLoader::XMLThemeLoader(const QString& filename)
  : m_pImpl(new XMLThemeLoaderImpl) {
  m_pImpl->load(filename);
}

XMLThemeLoader::~XMLThemeLoader() {
  delete m_pImpl;
  m_pImpl = nullptr;
}

QString XMLThemeLoader::name() const {
  if (m_pImpl->metadata.contains("name")) {
    const auto nameV = m_pImpl->metadata.value("name");
    if (nameV.typeId() == QMetaType::QString)
      return nameV.toString();
  }
  return QFileInfo(m_pImpl->filename).baseName();
}

const QVariantMap& XMLThemeLoader::metadata() const {
  return m_pImpl->metadata;
}

const QVariantMap& XMLThemeLoader::active() const {
  return m_pImpl->active;
}

const QVariantMap& XMLThemeLoader::inactive() const {
  return m_pImpl->inactive;
}

const QVariantMap& XMLThemeLoader::disabled() const {
  return m_pImpl->disabled;
}

const QVariantMap& XMLThemeLoader::constants() const {
  return m_pImpl->constants;
}

const QVariantMap& XMLThemeLoader::custom() const {
  return m_pImpl->custom;
}

bool XMLThemeLoader::isValid() const {
  if (m_pImpl->active.isEmpty())
    return false;
  if (m_pImpl->inactive.isEmpty())
    return false;
  if (m_pImpl->disabled.isEmpty())
    return false;
  return true;
}

QString XMLThemeLoader::filename() const {
  return m_pImpl->filename;
}

QOOL_NS_END
