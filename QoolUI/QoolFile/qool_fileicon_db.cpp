#include "qool_fileicon_db.h"

#include "qool_fileicon_imageprovider.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/plugin_loader.hpp"

#include <QMutex>

QOOL_NS_BEGIN

// 文件图标数据库（进程级 C++ 单例）：构造时经 PluginLoader 自动安装
// 全部 FileIconProvider 插件，按 priority 排序存入 provider 表；插件
// 缺失时发出警告且无法提供图标。路由语义（requestPath/requrestUrl
// 从高优先级向低优先级遍历询问，首个能提供结果者胜出）与 iconUrl
// 能力面见头文件注释；QML 消费面（iconUrl）由 FileIconHQ 提供。
// 单线程契约：本类无跨线程访问（插件安装与路由均主线程），不额外加锁。
QOOL_SIMPLE_SINGLETON_QT_IMPL(FileIconDB)

FileIconDB::FileIconDB()
  : QObject(nullptr) {
  auto_install_providers();
  xInfoQ << "initialized with" << m_providers.count() << "providers.";
}

FileIconDB::~FileIconDB() {
  // 防御性判空：provider 接口不保证继承 QObject（插件可提供纯 C++ 实现），
  // dynamic_cast 失败返回 nullptr，直接 deleteLater 是崩溃窗口。
  // 注：单例析构实际不可达（进程级生命周期），此清理仅为完整性。
  const auto keys = m_providers.keys();
  for (const auto& key : keys) {
    auto* x = dynamic_cast<QObject*>(m_providers.take(key));
    if (x)
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
  return FileIconImageProvider::compileUrl(
    fileUrl.toString(QUrl::PreferLocalFile));
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
