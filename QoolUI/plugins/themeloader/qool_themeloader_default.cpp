#include "qool_themeloader_default.h"

#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

DefaultThemeLoader::DefaultThemeLoader()
  : QObject { nullptr }
  , ThemeLoader() {
  xDebugQ << tr("QoolUI内置主题加载器已启动");
}

QMap<QString, QVariantMap> DefaultThemeLoader::themes() const {
  QMap<QString, QVariantMap> themes;
  themes.insert("default", QVariantMap {});
  return themes;
}

QOOL_NS_END
