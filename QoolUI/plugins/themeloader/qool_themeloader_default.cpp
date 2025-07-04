#include "qool_themeloader_default.h"

#include "qool_xml_theme_loader.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/simple_path_expander.hpp"

#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>
#include <QtConcurrent>

QOOL_NS_BEGIN

static const QString THEMES_DIR { ":/qoolui/themes" };

DefaultThemeLoader::DefaultThemeLoader()
  : QObject { nullptr }
  , ThemeLoader() {
  xInfoQ << "QoolUI default theme loader plugin initialized with "
            "default theme folder path:"
         << xDBGGreen << THEMES_DIR << xDBGReset;
}

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

  SimplePathExpander expander;
  expander.locations = locations;
  expander.subDirectories = sub_dirs;
  expander.extraLocations << THEMES_DIR;

  auto xml_files = expander.entryList({ "*.xml" });
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
    p.constants = loader->constants();
    p.custom = loader->custom();
    packages.append(p);
  }

  return packages;
}

QOOL_NS_END
