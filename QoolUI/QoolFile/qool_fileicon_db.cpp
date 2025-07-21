#include "qool_fileicon_db.h"

#include "qoolcommon/debug.hpp"
#include "qoolcommon/plugin_loader.hpp"

#include <QMutex>

QOOL_NS_BEGIN

QOOL_SIMPLE_SINGLETON_QT_IMPL(FileIconDB)

FileIconDB::FileIconDB()
  : QObject(nullptr) {
  auto_install_providers();
}

FileIconDB::~FileIconDB() {
  const auto keys = m_providers.keys();
  for (const auto& key : keys) {
    auto* x = dynamic_cast<QObject*>(m_providers.take(key));
    x->deleteLater();
  }
}

QString FileIconDB::requestPath(
  QAnyStringView id, const QSize& size) const {
  if (m_providers.isEmpty()) {
    xWarningQ
      << "No IconProvider-s installed. Cannot provide any icon.";
    return {};
  }

  auto keys = m_providers.keys();
  std::reverse(keys.begin(), keys.end());
  for (const auto& key : std::as_const(keys)) {
    auto provider = m_providers[key];
    auto res = provider->providePath(id, size);
    if (res.has_value())
      return res.value();
  }
  return {};
}

QUrl FileIconDB::requrestUrl(
  QAnyStringView id, const QSize& size) const {
  if (m_providers.isEmpty()) {
    xWarningQ
      << "No IconProvider-s installed. Cannot provide any icon.";
    return {};
  }

  auto keys = m_providers.keys();
  std::reverse(keys.begin(), keys.end());
  for (const auto& key : std::as_const(keys)) {
    auto provider = m_providers[key];
    auto res = provider->provideUrl(id, size);
    if (res.has_value())
      return res.value();
  }
  return {};
}

QUrl FileIconDB::iconUrl(const QUrl& fileUrl) const {
  static const QString url_pattern = QStringLiteral("image://%1/%2");
  return fileUrl;
  // TODO
}

void FileIconDB::auto_install_providers() {
  auto plugins = PluginLoader<FileIconProvider>::loadInstances();
  if (plugins.isEmpty()) {
    xWarningQ << "No FileIconPRovider plugin detected. QoolUI will not "
                 "be able to provide icons.";
    return;
  }

  PriorityFixer pFixer;

  for (auto iter = plugins.constBegin(); iter != plugins.constEnd();
    ++iter) {
    const auto plugin_name = iter.key();
    const auto plugin_info = iter.value();
    qreal priority = pFixer(plugin_info.priority, m_providers.keys());
    m_providers.insert(priority, plugin_info.instance);
    xInfoQ << "FilIconProvider" xDBGYellow << plugin_name
           << xDBGReset "installed.";
  }
}

QOOL_NS_END
