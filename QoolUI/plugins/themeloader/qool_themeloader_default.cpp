#include "qool_themeloader_default.h"

#include "qool_xml_theme_loader.h"
#include "qoolcommon/debug.hpp"

#include <QDir>
#include <QtConcurrent>

QOOL_NS_BEGIN

DefaultThemeLoader::DefaultThemeLoader()
  : QObject { nullptr }
  , ThemeLoader() {
  xDebugQ << tr("QoolUI内置主题加载器已启动");
}

QMap<QString, QVariantMap> DefaultThemeLoader::themes() const {
  QMap<QString, QVariantMap> themes;

  static const QString THEMES_DIR { ":/qoolui/themes" };

  QDir dir(THEMES_DIR);
  const QStringList xmls =
    dir.entryList(QStringList() << "*.xml", QDir::Files);

  QList<QSharedPointer<XMLThemeLoader>> loaders =
    QtConcurrent::blockingMapped(xmls, [](const QString& xml) {
      QString fullpath = QString("%1/%2").arg(THEMES_DIR).arg(xml);
      QSharedPointer<XMLThemeLoader> loader(
        new XMLThemeLoader(fullpath));
      return loader;
    });

  for (const auto& loader : std::as_const(loaders))
    themes.insert(loader->name(), loader->theme());

  xDebugQ << tr("成功载入了%1个主题").arg(loaders.length());

  return themes;
}

QOOL_NS_END
