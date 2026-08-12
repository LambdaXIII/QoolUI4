#ifndef QOOL_FILEINFO_HQ_H
#define QOOL_FILEINFO_HQ_H

#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QUrl>
#include <QVariantMap>

QOOL_NS_BEGIN

// 文件信息 QML 面（QML 单例，每 engine 独立实例）：转发 FileInfoDB 的
// getFileInfo ×2（命中 App 级共享缓存），实现调 FileInfoDB::instance()。
// 进程级数据（QCache + provider 表）单份在 FileInfoDB（C++ 全局单例，
// 不暴露 QML）——本类只承载 QML 面，多 engine 场景各 engine 一份
// 实例，互不共享对象，缓存跨 engine 共享命中。
class FileInfoHQ: public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(FileInfoHQ)
  QML_SINGLETON

public:
  static FileInfoHQ* create(QQmlEngine* engine, QJSEngine*) {
    return new FileInfoHQ(engine);
  }

  Q_INVOKABLE QVariantMap getFileInfo(const QUrl& fileUrl) const;
  Q_INVOKABLE QVariantMap getFileInfo(const QString& filePath) const;

private:
  explicit FileInfoHQ(QObject* parent = nullptr);
};

QOOL_NS_END

#endif // QOOL_FILEINFO_HQ_H
