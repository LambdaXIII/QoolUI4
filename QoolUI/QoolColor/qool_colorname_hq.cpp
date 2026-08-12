#include "qool_colorname_hq.h"

#include "qool_colorname_db.h"

QOOL_NS_BEGIN

/*!
    \qmltype ColorNameHQ
    \inqmlmodule Qool.Color
    \nativetype qoolui::ColorNameHQ
    \brief 颜色名 QML 面单例：汇总全部颜色名提供插件，提供名称 ↔
    颜色双向查询。

    ColorNameHQ 是 QML 单例，**每 QQmlEngine 一个独立实例**（经
    \c create() 创建，parent = engine）——多 engine 场景（QML 测试框架
    每文件建独立 engine、多窗口/多视图宿主）下各 engine 使用各自的
    ColorNameHQ 对象，互不共享。颜色名数据本身是 \b App 级共享的：
    底层 ColorNameDB（进程级 C++ 全局单例）持有插件表与名称缓存，
    构造时经 \c PluginLoader 自动安装全部 \c ColorNameProvider 插件，
    按插件 json 元数据的 \c priority 字段排序存入 provider 表；无插件
    安装时发出警告，此时仅 \c color()/name() 的默认值路径可用。

    \section1 插件优先级（priority）

    \list
    \li \c names() —— 全部 provider 的名称并集（可按 \c category 过滤，
        返回前排序）。
    \li \c color()/name() —— \b 按 priority 数值升序遍历，首个能给出
        结果（std::optional 有值）的 provider 胜出——"补充"型裁决
        （低数值 provider 提供基础色名，高数值 provider 仅补充其未覆盖
        的查询），\b 并非高优先级覆盖。全部无结果时
        \c color() 返回调用方传入的 \c def（默认白色），\c name()
        返回 \c QColor::name() 的 #RRGGBB/#AARRGGBB 文本。
    \li \c categories() —— 去重后返回，高优先级 provider 的类别在前。
    \endlist

    \note 优先级**统一定义在插件 json 元数据的 \c priority 字段**
    （\c PluginLoader 从元数据读取），接口 \c ColorNameProvider 刻意
    **不提供 \c priority() 方法**——防止实现方绕过 PluginLoader 的
    元数据裁决（改 json 即可调整覆盖顺序，无需改代码/重编译）。
    这是 v4 的约定性规范，后续维护不得向接口回加 priority()。

    \section1 名称缓存（hasColor）

    插件安装时各 provider 的名称被并入内部缓存 \c m_nameCache，
    \c hasColor() 基于该缓存做 O(1) 判定，不做 provider 遍历；
    因此安装后的新增名称不会反映到 \c hasColor()（插件静态声明
    色表，正常运行不存在该场景）。
*/

ColorNameHQ::ColorNameHQ(QObject* parent)
  : QObject(parent) {
}

QStringList ColorNameHQ::names(const QString& category) const {
  return ColorNameDB::instance()->names(category);
}

QColor ColorNameHQ::color(
  const QString& name, const QColor& def) const {
  return ColorNameDB::instance()->color(name, def);
}

QStringList ColorNameHQ::categories() const {
  return ColorNameDB::instance()->categories();
}

bool ColorNameHQ::hasColor(const QString& name) const {
  return ColorNameDB::instance()->hasColor(name);
}

QString ColorNameHQ::name(const QColor& c) const {
  return ColorNameDB::instance()->name(c);
}

QOOL_NS_END
