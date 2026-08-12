#ifndef QOOL_FILEICON_HQ_H
#define QOOL_FILEICON_HQ_H

#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QUrl>

QOOL_NS_BEGIN

// 文件图标 QML 面（QML 单例，每 engine 独立实例）：承载 QML 侧图标
// URL 编译（iconUrl）。实现直接调 FileIconImageProvider::compileUrl
// 静态——不碰 FileIconDB 状态（该静态函数本就等价于 DB 的 iconUrl
// 实现，少一跳转发）。进程级能力（provider 表 + 路由）在 FileIconDB
// （C++ 全局单例，不暴露 QML，供 FileIconImageProvider 的 C++ 路由
// 使用）——本类只承载 QML 面，多 engine 场景各 engine 一份实例。
class FileIconHQ: public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(FileIconHQ)
  QML_SINGLETON

public:
  static FileIconHQ* create(QQmlEngine* engine, QJSEngine*) {
    return new FileIconHQ(engine);
  }

  Q_INVOKABLE QUrl iconUrl(const QUrl& fileUrl) const;

private:
  explicit FileIconHQ(QObject* parent = nullptr);
};

QOOL_NS_END

#endif // QOOL_FILEICON_HQ_H
