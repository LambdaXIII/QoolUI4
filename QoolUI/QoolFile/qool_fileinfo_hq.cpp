#include "qool_fileinfo_hq.h"

#include "qool_fileinfo_db.h"

QOOL_NS_BEGIN

FileInfoHQ::FileInfoHQ(QObject* parent)
  : QObject(parent) {
}

QVariantMap FileInfoHQ::getFileInfo(const QUrl& fileUrl) const {
  return FileInfoDB::instance()->getFileInfo(fileUrl);
}

QVariantMap FileInfoHQ::getFileInfo(const QString& filePath) const {
  return FileInfoDB::instance()->getFileInfo(filePath);
}

QOOL_NS_END
