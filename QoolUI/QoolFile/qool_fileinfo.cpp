#include "qool_fileinfo.h"

#include "qool_fileinfo_db.h"

#include <utility>

QOOL_NS_BEGIN

size_t qHash(const FileInfo& info, size_t seed) noexcept {
  static const QString token { QStringLiteral("qoolfileinfo") };
  seed = qHashMulti(seed, token, info.absoluteFilePath());
  seed = qHashMulti(seed, info.birthTime(), info.lastModified());
  return seed;
}

FileInfo::FileInfo(const QUrl& fileUrl) {
  m_data = FileInfoDB::instance()->getFileInfo(fileUrl);
}

FileInfo::FileInfo(const QString& filePath) {
  m_data = FileInfoDB::instance()->getFileInfo(filePath);
}

FileInfo::FileInfo(const QFileInfo& info)
  : FileInfo(info.absoluteFilePath()) {
}

FileInfo::FileInfo(const QVariantMap& data)
  : m_data { data } {
}

FileInfo::FileInfo(const FileInfo& other)
  : m_data { other.m_data } {
}

FileInfo::FileInfo(FileInfo&& other)
  : m_data { std::move(other.m_data) } {
}

FileInfo& FileInfo::operator=(const FileInfo& other) {
  m_data = other.m_data;
  return *this;
}

FileInfo& FileInfo::operator=(FileInfo&& other) {
  m_data = std::move(other.m_data);
  return *this;
}

bool FileInfo::operator==(const FileInfo& other) const {
  return absoluteFilePath() == other.absoluteFilePath()
         && birthTime() == other.birthTime()
         && lastModified() == other.lastModified();
}

bool FileInfo::operator!=(const FileInfo& other) const {
  return ! operator==(other);
}

QVariant FileInfo::value(const QString& key) const {
  return m_data.value(key);
}

FileInfo::operator QVariantMap() const {
  return m_data;
}

bool FileInfo::isValid() const {
  return ! m_data.empty();
}

#define IMPL(T, N)                                                     \
  T FileInfo::N() const {                                              \
    return m_data.value(#N).value<T>();                                \
  }

#define __HANDLE__(N) IMPL(QString, N)
QOOL_FOREACH_4(__HANDLE__, fileName, filePath, baseName, suffix)
QOOL_FOREACH_4(__HANDLE__,
  absoluteFilePath,
  absolutePath,
  completeBaseName,
  completeSuffix)
QOOL_FOREACH_3(__HANDLE__, symLinkTarget, readSymLink, bundleName)
#undef __HANDLE__

#define __HANDLE__(N) IMPL(bool, N)
QOOL_FOREACH_5(
  __HANDLE__, isDir, isFile, isHidden, isReadable, isShortcut)
QOOL_FOREACH_5(
  __HANDLE__, isSymLink, isSymbolicLink, isWritable, exists, isBundle)
#undef __HANDLE__

#define __HANDLE__(N) IMPL(QDateTime, N)
QOOL_FOREACH_3(__HANDLE__, lastModified, lastRead, birthTime)
#undef __HANDLE__

IMPL(qint64, size)
IMPL(QUrl, url)
IMPL(QUrl, iconUrl)

#undef IMPL

QOOL_NS_END
