#include "qool_fileicon_hq.h"

#include "qool_fileicon_imageprovider.h"

QOOL_NS_BEGIN

FileIconHQ::FileIconHQ(QObject* parent)
  : QObject(parent) {
}

QUrl FileIconHQ::iconUrl(const QUrl& fileUrl) const {
  return FileIconImageProvider::compileUrl(
    fileUrl.toString(QUrl::PreferLocalFile));
}

QOOL_NS_END
