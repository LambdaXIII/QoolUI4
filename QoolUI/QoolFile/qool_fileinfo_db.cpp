#include "qool_fileinfo_db.h"

#include "qoolcommon/debug.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/plugin_loader.hpp"

#include <QFileInfo>
#include <QMutex>

QOOL_NS_BEGIN

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
  auto cache_info = m_cache->object(fileUrl);
  if (cache_info == nullptr
      || cache_info->value("lastModified") != __lastModified(fileUrl))
    generateCache(fileUrl);
  return *(m_cache->object(fileUrl));
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
  QOOL_FOREACH_4(
    _COPY, symLinkTarget, readSymLink, isBundle, bundleName)
#undef _COPY
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
