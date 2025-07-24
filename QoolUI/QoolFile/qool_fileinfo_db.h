#ifndef QOOL_FILEINFO_DB_H
#define QOOL_FILEINFO_DB_H

#include "qool_interface_fileinfoprovider.h"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QCache>
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class FileInfoDB: public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  QOOL_SIMPLE_SINGLETON_DECL(FileInfoDB)
  QOOL_SIMPLE_SINGLETON_QML_CREATE(FileInfoDB)

public:
  ~FileInfoDB();
  Q_INVOKABLE QVariantMap getFileInfo(const QUrl& fileUrl) const;
  Q_INVOKABLE QVariantMap getFileInfo(const QString& filePath) const;

protected:
  QCache<QUrl, QVariantMap>* m_cache;
  void generateCache(const QUrl& fileUrl) const;
  static QVariantMap generateCommonInfo(const QUrl& fileUrl);

  QMap<qreal, FileInfoProvider*> m_providers;
  void autoInstallProviders();
};

QOOL_NS_END

#endif // QOOL_FILEINFO_DB_H
