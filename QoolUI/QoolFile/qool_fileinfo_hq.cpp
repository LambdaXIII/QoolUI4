#include "qool_fileinfo_hq.h"

#include "qool_fileinfo_db.h"

QOOL_NS_BEGIN

/*!
    \qmltype FileInfoHQ
    \inqmlmodule Qool.File
    \nativetype qoolui::FileInfoHQ
    \brief 文件元信息 QML 面单例：文件信息查询（命中 App 级共享缓存）。

    FileInfoHQ 是 QML 单例，**每 QQmlEngine 一个独立实例**（经
    \c create() 创建，parent = engine）——多 engine 场景（QML 测试框架
    每文件建独立 engine、多窗口/多视图宿主）下各 engine 使用各自的
    FileInfoHQ 对象，互不共享。文件信息数据本身是 \b App 级共享的：
    底层 FileInfoDB（进程级 C++ 全局单例）以 QUrl 为键、QVariantMap
    为值缓存文件的通用信息（名称、路径、大小、时间戳、类型标志等，
    见 \c getFileInfo 返回字段）与各 FileInfoProvider 插件按优先级
    补充的信息；任意 engine 的 \c getFileInfo() 命中同一份缓存。

    \section1 缓存与失效
    缓存容量 2000 项，由 QCache 自动淘汰。命中时以磁盘文件的
    lastModified 时间戳与缓存值比对，文件被修改即重新生成缓存，
    保证返回信息始终新鲜。\c getFileInfo() 返回值拷贝，可按需多次调用。

    \section1 单线程契约
    底层缓存的查询/写入限定主线程（调用方——QML 引擎——天然满足）；
    跨线程访问经 Qt AutoConnection 排队。插件缺失时仅返回通用信息。
*/

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
