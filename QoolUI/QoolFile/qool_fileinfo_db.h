#ifndef QOOL_FILEINFO_DB_H
#define QOOL_FILEINFO_DB_H

#include "qool_interface_fileinfoprovider.h"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QCache>
#include <QObject>

QOOL_NS_BEGIN

// 文件信息数据库（进程级 C++ 单例）：QCache 缓存 + provider 表的唯一
// 持有者，缓存逻辑单份（跨 engine 共享命中）。不暴露 QML——Qt 契约：
// 共享实例经 QML_SINGLETON 暴露只能被一个 QQmlEngine 访问（多 engine
// 崩溃）。QML 面由 FileInfoHQ（每 engine 独立实例）承载并转发
// （getFileInfo，命中共享缓存），见 qool_fileinfo_hq.h；本类的 C++
// 消费面是 FileInfo 值类型。
class FileInfoDB: public QObject {
  Q_OBJECT
  QOOL_SIMPLE_SINGLETON_DECL(FileInfoDB)

public:
  ~FileInfoDB();
  QVariantMap getFileInfo(const QUrl& fileUrl) const;
  QVariantMap getFileInfo(const QString& filePath) const;

protected:
  QCache<QUrl, QVariantMap>* m_cache;
  void generateCache(const QUrl& fileUrl) const;
  static QVariantMap generateCommonInfo(const QUrl& fileUrl);

  QMap<qreal, FileInfoProvider*> m_providers;
  void autoInstallProviders();
};

QOOL_NS_END

#endif // QOOL_FILEINFO_DB_H
