#include "qool_themeloader_default.h"

#include "qool_xml_theme_loader.h"
#include "qoolcommon/debug.hpp"

#include <QDirIterator>

QOOL_NS_BEGIN

DefaultThemeLoader::DefaultThemeLoader()
  : QObject { nullptr }
  , ThemeLoader() {
  xDebugQ << tr("QoolUI内置主题加载器已启动");
}

QMap<QString, QVariantMap> DefaultThemeLoader::themes() const {
  QMap<QString, QVariantMap> themes;

  int count = 0;

  QDirIterator iter(":/qoolui/themes");
  while (iter.hasNext()) {
    const QString current = iter.next();
    xDebugQ << tr("正在加载主题：%1").arg(current);
    XMLThemeLoader loader(current);
    QVariantMap theme = loader.theme();
    QString name = loader.name();
    themes.insert(name, theme);
  }

  xDebugQ << tr("成功载入了%1个主题").arg(count);
  return themes;
}

QOOL_NS_END
