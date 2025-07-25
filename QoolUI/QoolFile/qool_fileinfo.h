#ifndef QOOL_FILEINFO_H
#define QOOL_FILEINFO_H

#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros_for_qgadget.hpp"
#include "qoolns.hpp"

#include <QDateTime>
#include <QFileInfo>
#include <QObject>
#include <QQmlEngine>
#include <QVariantMap>

QOOL_NS_BEGIN

class FileInfo;
size_t qHash(const FileInfo& info, size_t seed) noexcept;

class FileInfo {
  Q_GADGET
  QML_VALUE_TYPE(fileinfo)
  QML_CONSTRUCTIBLE_VALUE
public:
  FileInfo() = default;

  Q_INVOKABLE FileInfo(const QUrl& fileUrl);
  Q_INVOKABLE FileInfo(const QString& filePath);
  Q_INVOKABLE FileInfo(const QVariantMap& data);

  FileInfo(const QFileInfo& info);

  FileInfo(const FileInfo& other);
  FileInfo(FileInfo&& other);

  FileInfo& operator=(const FileInfo& other);
  FileInfo& operator=(FileInfo&& other);

  bool operator==(const FileInfo& other) const;
  bool operator!=(const FileInfo& other) const;

  Q_INVOKABLE QVariant value(const QString& key) const;
  Q_INVOKABLE operator QVariantMap() const;

  Q_INVOKABLE bool isValid() const;

  // friend size_t qHash(const FileInfo& info, size_t seed) noexcept;

private:
  QVariantMap m_data;

#define DECL(T, N) QOOL_PROPERTY_CONSTANT_DECL(T, N)

#define __HANDLE__(N) DECL(QString, N)
  QOOL_FOREACH_4(__HANDLE__, fileName, filePath, baseName, suffix)
  QOOL_FOREACH_4(__HANDLE__,
    absoluteFilePath,
    absolutePath,
    completeBaseName,
    completeSuffix)
  QOOL_FOREACH_3(__HANDLE__, symLinkTarget, readSymLink, bundleName)
#undef __HANDLE__

#define __HANDLE__(N) DECL(bool, N)
  QOOL_FOREACH_5(
    __HANDLE__, isDir, isFile, isHidden, isReadable, isShortcut)
  QOOL_FOREACH_5(
    __HANDLE__, isSymLink, isSymbolicLink, isWritable, exists, isBundle)
#undef __HANDLE__

#define __HANDLE__(N) DECL(QDateTime, N)
  QOOL_FOREACH_3(__HANDLE__, lastModified, lastRead, birthTime)
#undef __HANDLE__

  DECL(qint64, size)
  DECL(QUrl, url)
  DECL(QUrl, iconUrl)

#undef DECL
};

using FileInfoList = QList<FileInfo>;

QOOL_NS_END

#endif // QOOL_FILEINFO_H
