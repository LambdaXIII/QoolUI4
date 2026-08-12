#include "qool_theme_hq.h"

#include "qool_theme_db.h"

QOOL_NS_BEGIN

/*!
    \qmltype ThemeHQ
    \inqmlmodule Qool
    \nativetype qoolui::ThemeHQ
    \brief 主题 QML 面单例：主题查询、安装与前景对比色推荐。

    ThemeHQ 是 \l Qool 模块的 QML 单例，**每 QQmlEngine 一个独立实例**
    （经 \c create() 创建，parent = engine）——多 engine 场景（QML 测试
    框架每文件建独立 engine、多窗口/多视图宿主）下各 engine 使用各自的
    ThemeHQ 对象，互不共享。主题数据本身是 \b App 级共享的：底层
    ThemeDB（进程级 C++ 全局单例）持有全部主题与插件，任意 engine 的
    ThemeHQ 查询到的都是同一份数据；\c installTheme() 的安装结果对全部
    engine 立即可见（\c themeInstalled 信号在安装发生的 engine 内重发）。

    主题数据来源与注入方式：默认主题由系统调色板派生（\l SystemTheme）；
    主题插件经 \c PluginLoader 自动安装。宿主需要在启动前决策主题时，
    可在 C++ 侧操作 ThemeDB 预置数据（本类仅供 QML 面使用）。

    \section1 行为

    \list
    \li \c theme(name) —— 按名取主题（值类型 \l Theme）；未知名回退到
        已安装的首个主题。
    \li \c anyValue(group/key) —— 跨主题扫描：首个包含该键的主题的值
        胜出，全部无结果时返回默认值。
    \li \c installTheme(theme) —— 安装主题（写面）；重名或空名被拒绝
        且不发 \c themeInstalled。安装同时经底层模型发出 \c rowsInserted
        （\l ThemeHQModel 视图实时更新）。
    \li \c recommendForeground(bgColor, light, dark) / \c visualBrightness
        —— 静态工具：背景 → 黑/白对比前景推荐（亮度阈值 0.4/0.6）与
        感知亮度（0.299/0.587/0.114 加权）。
    \endlist

    \section1 属性

    \list
    \li \c themes —— 已安装主题名列表（只读）。
    \li \c count —— 已安装主题数量（只读）。
    \endlist
*/

ThemeHQ::ThemeHQ(QObject* parent)
  : QObject(parent) {
  // 信号重发：DB 是进程级单例（构造先于本类——instance() 首次调用
  // 即构造），跨 engine 的安装动作在各自 HQ 的 engine 内重发信号；
  // AutoConnection 处理跨线程自动排队（单线程契约，见 ThemeDB 注释）。
  // 注：themes/count 属性读 DB 但无变化通知——DB 的 themesChanged/
  // countChanged 从不发射（installTheme 只发 themeInstalled，与改造前
  // 行为一致）；QML 侧绑定 themes/count 不随安装刷新，需要实时列表请
  // 使用 ThemeHQModel。
  auto* db = ThemeDB::instance();
  connect(db, &ThemeDB::themeInstalled, this, &ThemeHQ::themeInstalled);
}

Theme ThemeHQ::theme(const QString& name) const {
  return ThemeDB::instance()->theme(name);
}

void ThemeHQ::installTheme(Theme theme) {
  ThemeDB::instance()->installTheme(std::move(theme));
}

QVariant ThemeHQ::anyValue(Theme::Groups group,
  const QString& key, const QVariant& defvalue) const {
  return ThemeDB::instance()->anyValue(group, key, defvalue);
}

QVariant ThemeHQ::anyValue(
  const QString& key, const QVariant& defvalue) const {
  return ThemeDB::instance()->anyValue(key, defvalue);
}

qreal ThemeHQ::visualBrightness(QColor color) {
  return ThemeDB::visualBrightness(color);
}

QColor ThemeHQ::recommendForeground(
  const QColor& bgColor, const QColor& light, const QColor& dark) {
  return ThemeDB::recommendForeground(bgColor, light, dark);
}

QStringList ThemeHQ::themes() const {
  return ThemeDB::instance()->themes();
}

int ThemeHQ::count() const {
  return ThemeDB::instance()->count();
}

QOOL_NS_END
