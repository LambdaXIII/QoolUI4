#ifndef QOOLPLUGIN_XML_THEME_LOADER_H
#define QOOLPLUGIN_XML_THEME_LOADER_H

#include "qoolns.hpp"

#include <QString>
#include <QVariantMap>

QOOL_NS_BEGIN

struct XMLThemeLoader {
  static QVariantMap load(const QString& path);
  static QString getThemeName(const QString& path);
};

QOOL_NS_END

#endif // QOOLPLUGIN_XML_THEME_LOADER_H