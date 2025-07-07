#ifndef QOOLCOMMON_PLUGIN_LOADER_HPP
#define QOOLCOMMON_PLUGIN_LOADER_HPP

#include "qoolns.hpp"

#include <QAnyStringView>
#include <QCoreApplication>
#include <QDebug>
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
    return result;
  }

  QStringList plugins() const {
    QStringList result;
    const auto pluginFolders = pluginSearchPaths();
    for (const QString& dir : pluginFolders) {
      qDebug() << "searching:" << dir;
      QDirIterator iter(dir);
      while (iter.hasNext()) {
        auto a = iter.next();
        if (QLibrary::isLibrary(a)) {
          result << a;
          qDebug() << "found:" << a;
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
  using InstanceMap = QMultiHash<QString, Interface*>;

  static inline InstanceMap loadInstances() {
    QOOL_NS::PluginScanner scanner(QOOL_PLUGIN_DIR);
    auto plugins = scanner.plugins();
    if (plugins.isEmpty())
      return {};

    InstanceMap result;

    for (const auto& pluginPath : plugins) {
      QScopedPointer<QPluginLoader> loader { new QPluginLoader(
        pluginPath) };

      auto ins_object = loader->instance();
      qDebug() << loader->fileName() << ins_object;

      Interface* ins_interface = qobject_cast<Interface*>(ins_object);
      if (ins_interface == nullptr) {
        loader->unload();
        continue;
      }
      QString plugin_name =
        QOOL_NS::pluginMetadata(*loader, "name").toString();
      if (plugin_name.isEmpty())
        plugin_name = QFileInfo(pluginPath).baseName();
      result.insert(plugin_name, ins_interface);
    }
    qDebug() << result;
    return result;
  }
};

QOOL_NS_END

#endif // QOOLCOMMON_PLUGIN_LOADER_HPP
