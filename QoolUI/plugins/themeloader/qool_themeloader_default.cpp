#include "qool_themeloader_default.h"

#include "qool_xml_theme_loader.h"
#include "qoolcommon/debug.hpp"

#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>
#include <QtConcurrent>

QOOL_NS_BEGIN

DefaultThemeLoader::DefaultThemeLoader()
  : QObject { nullptr }
  , ThemeLoader() {
  xDebugQ << tr("QoolUI内置主题加载器已启动");
}

static const QString THEMES_DIR { ":/qoolui/themes" };

QStringList scan_for_xml_files() {
  QStringList locations;
  locations << QCoreApplication::applicationDirPath()
            << QCoreApplication::libraryPaths()
            << QStandardPaths::standardLocations(
                 QStandardPaths::AppLocalDataLocation)
            << QStandardPaths::standardLocations(
                 QStandardPaths::AppDataLocation)
            << QStandardPaths::standardLocations(
                 QStandardPaths::GenericDataLocation)
            << QStandardPaths::standardLocations(
                 QStandardPaths::GenericConfigLocation)
            << QStandardPaths::standardLocations(
                 QStandardPaths::AppConfigLocation);
  static const QStringList sub_dirs { "theme", "themes", "qooltheme",
    "qoolthemes" };
  QStringList search_paths;
  for (const QString& location : locations) {
    search_paths << location;
    for (const QString& sub_dir : sub_dirs)
      search_paths << location + "/" + sub_dir;
  }
  search_paths << THEMES_DIR;

  QStringList xml_files;
  for (const QString& path : search_paths) {
    QDir dir(path);
    if (! dir.exists() || ! dir.isReadable())
      continue;
    auto files =
      dir.entryInfoList(QStringList() << "*.xml", QDir::Files);
    for (const QFileInfo& file : files)
      xml_files << file.absoluteFilePath();
  }

  std::stable_sort(xml_files.begin(), xml_files.end());
  auto result = std::unique(xml_files.begin(), xml_files.end());
  xml_files.erase(result, xml_files.end());
  xml_files.shrink_to_fit();

  for (const QString& xml_file : xml_files)
    xInfo << "Found xml theme file:" << xDBGGreen << xml_file
          << xDBGReset;
  return xml_files;
}

QList<ThemeLoader::Package> DefaultThemeLoader::themes() const {
  QList<Package> packages;

  const QStringList xmls = scan_for_xml_files();

  QList<QSharedPointer<XMLThemeLoader>> loaders =
    QtConcurrent::blockingMapped(xmls, [](const QString& xmlPath) {
      QSharedPointer<XMLThemeLoader> loader(
        new XMLThemeLoader(xmlPath));
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
