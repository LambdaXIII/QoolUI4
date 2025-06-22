#ifndef QOOLCOMMON_PLUGIN_LOADER_HPP
#define QOOLCOMMON_PLUGIN_LOADER_HPP

#include "qoolns.hpp"

#include <QAnyStringView>
#include <QCoreApplication>
#include <QDirIterator>
#include <QFileInfo>
#include <QLibrary>
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
  explicit PluginScanner(QAnyStringView subfoldere) {
    m_subfolders << subfoldere.toString();
  }
  PluginScanner& addSubFolder(QAnyStringView f) {
    m_subfolders << f.toString();
    return *this;
  }

  PluginScanner& addExtraPath(const QString& p) {
    m_extraFolders << p;
    return *this;
  }
  PluginScanner& set_defaultPathEnabled(bool v) {
    m_defaultPathEnabled = v;
    return *this;
  }
  QStringList pluginPaths() const {
    QStringList result;
    QSet<QString> rawPaths;

    if (m_defaultPathEnabled) {
      for (const auto& libPath : QCoreApplication::libraryPaths())
        rawPaths << libPath;
      rawPaths << QCoreApplication::applicationDirPath();
    }

    for (const auto& extraPath : m_extraFolders)
      rawPaths << extraPath;

    if (m_subfolders.isEmpty())
      result = QStringList(rawPaths.constBegin(), rawPaths.constEnd());
    else
      for (const auto& sub : m_subfolders) {
        std::for_each(
          rawPaths.cbegin(), rawPaths.cend(), [&](const QString& x) {
            auto n = x + '/' + sub;
            result << n;
          });
      }

    result.removeIf([](const QString& x) {
      QFileInfo p(x);
      bool good = p.exists() && p.isDir();
      return ! good;
    });
    std::sort(result.begin(), result.end());
    auto last = std::unique(result.begin(), result.end());
    result.erase(last, result.end());
    result.squeeze();
    return result;
  }

  QStringList plugins() const {
    QStringList result;
    for (const QString& dir : pluginPaths()) {
      QDirIterator iter(dir);
      while (iter.hasNext()) {
        auto a = iter.next();
        if (QLibrary::isLibrary(a))
          result << a;
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

  static InstanceMap loadInstances() {
    QOOL_NS::PluginScanner scanner(QOOL_PLUGIN_DIR);
    scanner.addExtraPath(QCoreApplication::applicationDirPath());
    auto plugins = scanner.plugins();
    if (plugins.isEmpty())
      return {};

    InstanceMap result;

    for (const auto& pluginPath : plugins) {
      QScopedPointer<QPluginLoader> loader { new QPluginLoader(
        pluginPath) };
      auto ins_object = loader->instance();

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

    return result;
  }
};

QOOL_NS_END

#endif // QOOLCOMMON_PLUGIN_LOADER_HPP