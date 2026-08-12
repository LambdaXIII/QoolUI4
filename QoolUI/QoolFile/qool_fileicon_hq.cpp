#include "qool_fileicon_hq.h"

#include "qool_fileicon_imageprovider.h"

QOOL_NS_BEGIN

/*!
    \qmltype FileIconHQ
    \inqmlmodule Qool.File
    \nativetype qoolui::FileIconHQ
    \brief 文件图标 QML 面单例：本地文件 → 图标 URL。

    FileIconHQ 是 QML 单例，**每 QQmlEngine 一个独立实例**（经
    \c create() 创建，parent = engine）——多 engine 场景（QML 测试框架
    每文件建独立 engine、多窗口/多视图宿主）下各 engine 使用各自的
    FileIconHQ 对象，互不共享。图标数据本身是 \b App 级共享的：底层
    FileIconDB（进程级 C++ 全局单例）持有 provider 表（构造时经
    \c PluginLoader 自动安装全部 \c FileIconProvider 插件，按 priority
    排序）与 \c image://qoolfileicon 协议的路由；插件缺失时无法提供
    图标（警告）。

    \section1 iconUrl

    \c iconUrl(fileUrl) 将本地文件路径编译为 \c image://qoolfileicon
    协议的图标 URL（等价 \c FileIconImageProvider::compileUrl），供
    \l {Image} 等组件直接加载。注意：\c image://qoolfileicon 的解析
    由模块插件注册的 ImageProvider 完成，宿主无需额外注册。
*/

FileIconHQ::FileIconHQ(QObject* parent)
  : QObject(parent) {
}

QUrl FileIconHQ::iconUrl(const QUrl& fileUrl) const {
  return FileIconImageProvider::compileUrl(
    fileUrl.toString(QUrl::PreferLocalFile));
}

QOOL_NS_END
