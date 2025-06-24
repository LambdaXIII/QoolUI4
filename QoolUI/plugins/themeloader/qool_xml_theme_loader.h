#ifndef QOOLPLUGIN_XML_THEME_LOADER_H
#define QOOLPLUGIN_XML_THEME_LOADER_H

#include "qoolns.hpp"

#include <QString>
#include <QVariantMap>

QOOL_NS_BEGIN
class XMLThemeLoaderImpl;
class XMLThemeLoader {
public:
  explicit XMLThemeLoader(const QString& xmlPath);
  ~XMLThemeLoader();

  QString name() const;
  const QVariantMap& theme() const;
  const QVariantMap& metadata() const;

protected:
  XMLThemeLoaderImpl* m_pImpl;
};

QOOL_NS_END

#endif // QOOLPLUGIN_XML_THEME_LOADER_H
