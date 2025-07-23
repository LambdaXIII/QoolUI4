#include "qool_fileicon_imageprovider.h"

#include "qool_fileicon_db.h"

QOOL_NS_BEGIN

FileIconImageProvider::FileIconImageProvider()
  : QQuickImageProvider { QQuickImageProvider::Pixmap,
    QQmlImageProviderBase::ForceAsynchronousImageLoading } {
}

QPixmap FileIconImageProvider::requestPixmap(
  const QString& id, QSize* size, const QSize& requestedSize) {
  QPixmap result { requestedSize.isValid() ? requestedSize :
                                             QSize(64, 64) };

  const auto icon_path =
    FileIconDB::instance()->requestPath(id, result.size());

  QImage image { icon_path };

  if (image.isNull()) {
    result.fill(Qt::white);
  } else {
    QImage scaled_img = image;
    if (requestedSize.isValid())
      scaled_img = image.scaled(
        requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    result = QPixmap::fromImage(scaled_img);
  }

  if (size)
    *size = result.size();

  return result;
}

QString FileIconImageProvider::schema() {
  return QStringLiteral("qoolfileicon");
}

QUrl FileIconImageProvider::compileUrl(QAnyStringView filePath) {
  static const QString url_pattern { QStringLiteral("image://%1/%2") };
  return { url_pattern.arg(schema(), filePath.toString()) };
}

QOOL_NS_END
