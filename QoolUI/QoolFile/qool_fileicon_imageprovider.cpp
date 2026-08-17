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
  // 路径中的 '%' 会被 QUrl 当作百分号转义序列：恰为合法十六进制时
  // 路径失真（"50%20off.png" → "50 off.png"），非法时解析异常——
  // 必须先行 URL 片段转义。provider 端 id 经 QUrl::path() 自动解码
  // 还原，无需手动 fromPercentEncoding。
  static const QString url_pattern { QStringLiteral("image://%1/%2") };
  const QString encoded = QString::fromLatin1(
    QUrl::toPercentEncoding(filePath.toString()));
  return { url_pattern.arg(schema(), encoded) };
}

QOOL_NS_END
