#ifndef QOOL_FILEICON_IMAGEPROVIDER_H
#define QOOL_FILEICON_IMAGEPROVIDER_H

#include "qoolns.hpp"

#include <QObject>
#include <QQuickImageProvider>

QOOL_NS_BEGIN

class FileIconImageProvider: public QQuickImageProvider {
  Q_OBJECT
public:
  FileIconImageProvider();

  QPixmap requestPixmap(const QString& id, QSize* size,
    const QSize& requestedSize) override;

  static QString schema();
  static QUrl compileUrl(QAnyStringView filePath);
};

QOOL_NS_END

#endif // QOOL_FILEICON_IMAGEPROVIDER_H
