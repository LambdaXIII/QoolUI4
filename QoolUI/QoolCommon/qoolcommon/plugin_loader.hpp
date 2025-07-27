#ifndef QOOLCOMMON_PLUGIN_LOADER_HPP
#define QOOLCOMMON_PLUGIN_LOADER_HPP

#include "debug.hpp"
#include "qoolns.hpp"

#include <QAnyStringView>
#include <QCoreApplication>
#include <QDirIterator>
#include <QFileInfo>
#include <QLibrary>
#include <QLibraryInfo>
#include <QPluginLoader>
#include <QSet>
#include <QString>
#include <QStringList>

QOOL_NS_BEGIN

class PluginScanner {
  QStringList m_subfolders;
  bool m_defaultPathEnabled { true };
  QStringList m_extraFolders;

public:
  PluginScanner() = default;
  explicit PluginScanner(QAnyStringView subfolder) {
    m_subfolders << subfolder.toString();
  }

  PluginScanner& addSubFolder(QAnyStringView f) {
    m_subfolders << f.toString();
    return *this;
  }

  PluginScanner& addSubFolders(const QStringList fs) {
    for (const auto f : fs)
      m_subfolders << f;
    return *this;
  }

  PluginScanner& addExtraPath(const QString& p) {
    m_extraFolders << p;
    return *this;
  }

  PluginScanner& addExtraPaths(const QStringList& ps) {
    for (const auto& p : ps)
      m_extraFolders << p;
    return *this;
  }

  PluginScanner& set_defaultPathEnabled(bool v) {
    m_defaultPathEnabled = v;
    return *this;
  }

  QStringList pluginSearchPaths() const {
    QStringList result;
    QStringList parentFolders;

    if (m_defaultPathEnabled) {
      xInfo << xDBGToken("QoolPluginScanner")
            << "Invoking default search paths ...";
      parentFolders << QLibraryInfo::paths(QLibraryInfo::PluginsPath)
                    << QLibraryInfo::paths(QLibraryInfo::QmlImportsPath)
                    << QLibraryInfo::paths(QLibraryInfo::LibrariesPath)
                    << QLibraryInfo::paths(QLibraryInfo::PrefixPath)
                    << QCoreApplication::applicationDirPath();
    }

    parentFolders << m_extraFolders;

    if (m_subfolders.isEmpty())
      result = parentFolders;
    else
      for (const auto& parentFolder : std::as_const(parentFolders))
        for (const auto& subFolder : std::as_const(m_subfolders)) {
          const QString x = parentFolder + "/" + subFolder;
          const QFileInfo info(x);
          if (! info.isDir() || ! info.exists())
            continue;
          result << QFileInfo(x).absoluteFilePath();
        }

    std::stable_sort(result.begin(), result.end());

    auto last = std::unique(result.begin(), result.end());
    result.erase(last, result.end());
    result.shrink_to_fit();
    xInfo << xDBGToken("QoolPluginScanner")
          << "final search paths:" << xDBGList(result);
    return result;
  }

  QStringList plugins() const {
    QStringList result;
    const auto pluginFolders = pluginSearchPaths();
    for (const QString& dir : pluginFolders) {
      QDirIterator iter(dir);
      while (iter.hasNext()) {
        auto a = iter.next();
        if (QLibrary::isLibrary(a)) {
          result << a;
        }
      }
    }
    return result;
  }
}; // pluginscanner

inline QJsonValue pluginMetadata(
  QPluginLoader& loader, QAnyStringView key) {
  return loader.metaData()
    .value("MetaData")
    .toObject()
    .value(key.toString());
}

class PriorityFixer {
  qreal m_step { 0.01 };

public:
  PriorityFixer(qreal stepValue = 0.01)
    : m_step { stepValue } {}
  template <typename KeyContainer>
  qreal operator()(int priority, const KeyContainer& keys) {
    qreal p(priority);
    while (std::find(keys.cbegin(), keys.cend(), p) != keys.cend())
      p += m_step;
    return p;
  }
};

template <typename Interface>
struct PluginLoader {
  struct InstanceInfo {
    int priority;
    QString name;
    QString description;
    Interface* instance;
  };
  using InstanceMap = QMultiHash<QString, InstanceInfo>;

  static inline std::optional<InstanceInfo> loadInstance(
    QPluginLoader* loader) {
    auto ins_obj = loader->instance();
    if (! ins_obj) {
      xWarning << xDBGToken("QoolUIPluginLoader")
               << "Failed loading qoolplugin:" << xDBGRed
               << loader->fileName() << xDBGYellow
               << "set QT_DEBUG_PLUGINS to 1 to debug plugins."
               << xDBGReset;
      return std::nullopt;
    }

    auto ins_interface = qobject_cast<Interface*>(ins_obj);
    if (ins_interface == nullptr) {
      loader->unload();
      return std::nullopt;
    }

    InstanceInfo info;
    info.instance = ins_interface;
    info.name = QOOL_NS::pluginMetadata(*loader, "name").toString();
    info.description =
      QOOL_NS::pluginMetadata(*loader, "description").toString();
    info.priority =
      QOOL_NS::pluginMetadata(*loader, "priority").toInt();
    return { info };
  }

  static inline InstanceMap loadInstances() {
    QOOL_NS::PluginScanner scanner(QOOL_PLUGIN_DIR);
    auto plugins = scanner.plugins();
    if (plugins.isEmpty())
      return {};

    InstanceMap result;

    for (const auto& pluginPath : plugins) {
      QScopedPointer<QPluginLoader> loader { new QPluginLoader(
        pluginPath) };

      auto info = loadInstance(loader.data());
      if (! info.has_value())
        continue;

      auto i = info.value();
      result.insert(i.name, i);

      xInfo << xDBGToken("QoolUIPluginLoader")
            << "Found qoolplugin:" << xDBGGreen << loader->fileName()
            << xDBGReset << "loaded as" << xDBGBlue << info->name
            << xDBGYellow << info->instance << xDBGReset;
    }

    return result;
  }
};

QOOL_NS_END

#endif // QOOLCOMMON_PLUGIN_LOADER_HPP
