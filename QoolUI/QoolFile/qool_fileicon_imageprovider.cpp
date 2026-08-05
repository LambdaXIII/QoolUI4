#include "qool_fileicon_imageprovider.h"

#include "qool_fileicon_db.h"

QOOL_NS_BEGIN

/*!
    \qmltype FileIconImageProvider
    \inqmlmodule Qool.File
    \nativetype qoolui::FileIconImageProvider
    \brief 以 image://qoolfileicon 协议提供文件系统图标（pixmap）。

    \c schema() 返回协议名 \c qoolfileicon；配合 QQmlEngine 注册后，
    \c image://qoolfileicon/<编码后的文件路径> 即解析为该文件的图标。
    requestPixmap() 把 id 交给 FileIconDB 路由到具体 provider 取图标：
    请求尺寸有效则按 KeepAspectRatio + SmoothTransformation 缩放，
    否则取默认 64×64；路径无效时返回白色占位图。

    \section1 compileUrl 百分号转义
    compileUrl() 先把文件路径经 QUrl::toPercentEncoding 百分号编码再拼入
    URL：路径中的 '%' 会被 QUrl 当作百分号转义序列，恰为合法十六进制时
    路径失真（如 "50%20off.png" 变 "50 off.png"），非法时解析异常——
    必须先行 URL 片段转义。编码后 provider 端 id 经 QUrl::path() 自动
    解码还原，无需手动 fromPercentEncoding。

    \note 异步加载：构造指定 ForceAsynchronousImageLoading，图标解码
    不阻塞渲染线程。
*/
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
