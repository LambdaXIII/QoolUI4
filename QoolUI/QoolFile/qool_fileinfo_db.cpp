#include "qool_fileinfo_db.h"

#include "qool_fileicon_imageprovider.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/plugin_loader.hpp"

#include <QFileInfo>
#include <QMutex>

QOOL_NS_BEGIN

/*!
    \qmltype FileInfoDB
    \inqmlmodule Qool.File
    \nativetype qoolui::FileInfoDB
    \brief 文件元信息的全局缓存单例（QML 单例，进程级生命周期）。

    以 QUrl 为键、QVariantMap 为值，缓存文件的通用信息（名称、路径、
    大小、时间戳、类型标志等，见 \c generateCommonInfo）与各
    FileInfoProvider 插件按优先级补充的信息；\c getFileInfo() 返回
    值拷贝，可按需多次调用。

    \section1 缓存与失效
    缓存容量 2000 项，由 QCache 自动淘汰。命中时以磁盘文件的
    lastModified 时间戳与缓存值比对，文件被修改即重新生成缓存
    （generateCache），保证返回信息始终新鲜。

    \section1 单线程契约
    \c getFileInfo() 声明为 const 却会写入 QCache——QCache 非线程
    安全，调用方必须限定主线程（模型等消费方均为主线程，无需加锁）。
    防御性判空：QCache 淘汰策略下 object() 可能失效，直接解引用
    nullptr 是崩溃窗口。
*/
QOOL_SIMPLE_SINGLETON_QT_IMPL(FileInfoDB)

FileInfoDB::FileInfoDB()
  : QObject(nullptr)
  , m_cache(new QCache<QUrl, QVariantMap>(2000)) {
}

FileInfoDB::~FileInfoDB() {
  m_cache->clear();
  delete m_cache;
}

QDateTime __lastModified(const QUrl& fileUrl) {
  return QFileInfo(fileUrl.toString(QUrl::PreferLocalFile))
    .lastModified();
}

QVariantMap FileInfoDB::getFileInfo(const QUrl& fileUrl) const {
  // 单线程契约：本方法 const 却写入 QCache（QCache 非线程安全），
  // 调用方须限定主线程（模型等消费方均为主线程，无需加锁）
  auto cache_info = m_cache->object(fileUrl);
  if (cache_info == nullptr
      || cache_info->value("lastModified") != __lastModified(fileUrl))
    generateCache(fileUrl);
  // 防御性判空：QCache 淘汰策略下 object() 可能失效，
  // 直接解引用 nullptr 是崩溃窗口
  auto result = m_cache->object(fileUrl);
  return result ? *result : QVariantMap {};
}

QVariantMap FileInfoDB::getFileInfo(const QString& filePath) const {
  return getFileInfo(QUrl::fromLocalFile(filePath));
}

void FileInfoDB::generateCache(const QUrl& fileUrl) const {
  QVariantMap* info = new QVariantMap;
  info->insert(generateCommonInfo(fileUrl));

  for (auto iter = m_providers.constBegin();
    iter != m_providers.constEnd();
    ++iter) {
    auto* provider = iter.value();
    if (provider->canProvide(fileUrl))
      info->insert(provider->provide(fileUrl));
  }

  m_cache->insert(fileUrl, info);
}

QVariantMap FileInfoDB::generateCommonInfo(const QUrl& fileUrl) {
  const QFileInfo info(fileUrl.toString(QUrl::PreferLocalFile));
  QVariantMap result;
  result["originalInput"] = fileUrl.toString();
#define _COPY(N) result[#N] = QVariant::fromValue(info.N());
  QOOL_FOREACH_3(_COPY, lastModified, lastRead, birthTime)
  QOOL_FOREACH_8(_COPY,
    fileName,
    filePath,
    baseName,
    absoluteFilePath,
    absolutePath,
    completeBaseName,
    completeSuffix,
    suffix)
  QOOL_FOREACH_9(_COPY,
    isDir,
    isFile,
    isHidden,
    isReadable,
    isShortcut,
    isSymLink,
    isSymbolicLink,
    isWritable,
    exists)
  QOOL_FOREACH_5(
    _COPY, symLinkTarget, readSymLink, isBundle, bundleName, size)
#undef _COPY
  result["url"] = QUrl::fromLocalFile(info.absoluteFilePath());
  result["iconUrl"] =
    FileIconImageProvider::compileUrl(info.absoluteFilePath());
  return result;
}

void FileInfoDB::autoInstallProviders() {
  auto plugins = PluginLoader<FileInfoProvider>::loadInstances();
  if (plugins.isEmpty()) {
    xWarningQ << xDBGRed "No FileInfoProvider-s detected." xDBGReset;
    return;
  }
  PriorityFixer pFixer;
  for (auto iter = plugins.constBegin(); iter != plugins.constEnd();
    ++iter) {
    const auto info = iter.value();
    qreal priority = pFixer(info.priority, m_providers.keys());
    m_providers.insert(priority, info.instance);
    xInfoQ << "FileInfoProvider" << xDBGBlue << info.name
           << xDBGReset "installed.";
  }
}

QOOL_NS_END
