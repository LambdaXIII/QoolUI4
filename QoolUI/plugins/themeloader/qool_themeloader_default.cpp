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

QList<ThemeLoader::Package> DefaultThemeLoader::themes() const {
  QList<Package> packages;

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

  for (const auto& loader : std::as_const(loaders)) {
    if (! loader->isValid()) {
      xWarningQ << xDBGRed << loader->filename() << xDBGReset
                << "might not be a valid theme file.";
      continue;
    }
    Package p;
    p.name = loader->name();
    p.active = loader->active();
    p.inactive = loader->inactive();
    p.disabled = loader->disabled();
    packages.append(p);
  }

  xDebugQ << tr("成功载入了%1个主题").arg(loaders.length());

  return packages;
}

QOOL_NS_END
