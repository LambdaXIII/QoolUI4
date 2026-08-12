#ifndef QOOL_FILEICON_DB_H
#define QOOL_FILEICON_DB_H

#include "qool_interface_fileiconprovider.h"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QSize>

QOOL_NS_BEGIN

// 文件图标数据库（进程级 C++ 单例）：provider 表与图标路由的唯一持有者。
// 不暴露 QML——Qt 契约：共享实例经 QML_SINGLETON 暴露只能被一个
// QQmlEngine 访问（多 engine 崩溃）。QML 面由 FileIconHQ（每 engine
// 独立实例）承载（iconUrl，见 qool_fileicon_hq.h）；本类的 C++ 消费面
// 是 FileIconImageProvider（requestPath 路由）。
class FileIconDB: public QObject {
  Q_OBJECT
  QOOL_SIMPLE_SINGLETON_DECL(FileIconDB)

public:
  ~FileIconDB();

  QString requestPath(QAnyStringView id, const QSize& size = {}) const;
  QUrl requrestUrl(QAnyStringView id, const QSize& size = {}) const;

  // 纯 C++ 能力面：本地路径 → image://qoolfileicon 协议 URL
  //（等价 FileIconImageProvider::compileUrl；QML 面走 FileIconHQ）。
  QUrl iconUrl(const QUrl& fileUrl) const;

protected:
  QMap<qreal, FileIconProvider*> m_providers;
  void auto_install_providers();
};

QOOL_NS_END

#endif // QOOL_FILEICON_DB_H
