#include "qool_colornamedatabase.h"

#include "qoolcommon/debug.hpp"
#include "qoolcommon/plugin_loader.hpp"

#include <algorithm>

QOOL_NS_BEGIN

/*!
    \qmltype ColorDB
    \inqmlmodule Qool.Color
    \nativetype qoolui::ColorNameDatabase
    \brief 颜色名数据库单例：汇总全部颜色名提供插件，提供名称 ↔ 颜色
    双向查询。

    ColorDB 是进程级 QML 单例（QML_SINGLETON），构造时经
    \c PluginLoader 自动安装全部 \c ColorNameProvider 插件，按插件
    json 元数据的 \c priority 字段排序存入 provider 表；无插件安装时
    发出警告，此时仅 \c color()/name() 的默认值路径可用。

    \section1 插件优先级（priority）

    多插件并存时的裁决语义（v4 约定，见 qool-plugin-interfaces 页面）：

    \list
    \li \c names() —— 全部 provider 的名称并集（可按 \c category 过滤，
        返回前排序）。
    \li \c color()/name() —— 从高优先级向低优先级遍历，首个能给出
        结果（std::optional 有值）的 provider 胜出；全部无结果时
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

    \section1 生命周期与清理

    单例析构实际不可达（进程级生命周期），析构清理仅为完整性：
    provider 接口不保证继承 QObject（插件可提供纯 C++ 实现），
    dynamic_cast 失败返回 nullptr，直接 deleteLater 是崩溃窗口，
    故先判空再清理。
*/
QOOL_SIMPLE_SINGLETON_QT_IMPL(ColorNameDatabase)

void ColorNameDatabase::installPlugins() {
  PriorityFixer pFixer;
  auto plugins = PluginLoader<ColorNameProvider>::loadInstances();
  if (plugins.isEmpty()) {
    xWarningQ << "No ColorNameProvider plugin detected. ColorDB has no "
                 "color names available.";
    return;
  }

  for (auto iter = plugins.constBegin(); iter != plugins.constEnd();
    ++iter) {
    const QString name = iter.key();
    const auto info = iter.value();
    ColorNameProvider* plugin = info.instance;
    qreal priority = pFixer(info.priority, m_providers.keys());
    m_providers.insert(priority, plugin);
    const auto names = plugin->names();
    m_nameCache.unite({ names.constBegin(), names.constEnd() });
    xDebugQ << tr("已安装插件" xDBGCyan "%1" xDBGReset
                  ",优先级:" xDBGRed "%2" xDBGReset)
                 .arg(name)
                 .arg(priority);
  }
}

QColor ColorNameDatabase::decode(
  std::optional<ColorNameProvider::QoolRGBA> rgba) {
  QColor result = Qt::black;
  if (rgba.has_value()) {
    auto v = rgba.value();
    result = QColor::fromRgbF(v.at(0), v.at(1), v.at(2), v.at(3));
  }
  return result;
}

ColorNameProvider::QoolRGBA ColorNameDatabase::encode(const QColor& c) {
  return { c.redF(), c.greenF(), c.blueF(), c.alphaF() };
}

ColorNameDatabase::ColorNameDatabase()
  : QObject { nullptr } {
  installPlugins();
  xInfoQ << "initialized with" << m_providers.count() << "providers.";
}

ColorNameDatabase::~ColorNameDatabase() {
  // 防御性判空：provider 接口不保证继承 QObject（插件可提供纯 C++ 实现），
  // dynamic_cast 失败返回 nullptr，直接 deleteLater 是崩溃窗口。
  // 注：单例析构实际不可达（进程级生命周期），此清理仅为完整性。
  const auto keys = m_providers.keys();
  for (const auto& key : keys) {
    auto* x = dynamic_cast<QObject*>(m_providers.take(key));
    if (x)
      x->deleteLater();
  }
}

QStringList ColorNameDatabase::names(const QString& category) const {
  QSet<QString> result;

  for (auto* provider : m_providers) {
    bool fit = category.isEmpty() || category == provider->category();
    if (! fit)
      continue;
    const auto ns = provider->names();
    result.unite({ ns.constBegin(), ns.constEnd() });
  }

  QStringList resultList { result.constBegin(), result.constEnd() };
  std::sort(resultList.begin(), resultList.end());
  return resultList;
}

QColor ColorNameDatabase::color(
  const QString& name, const QColor& def) const {
  auto keys = m_providers.keys();
  std::reverse(keys.begin(), keys.end());
  for (const auto& key : std::as_const(keys)) {
    auto c = m_providers.value(key)->color(name);
    if (c)
      return decode(c);
  }
  return def;
}

QStringList ColorNameDatabase::categories() const {
  QSet<QString> cache;
  QStringList result;
  for (auto* p : m_providers) {
    const auto c = p->category();
    if (cache.contains(c))
      continue;
    cache.insert(c);
    result.prepend(c);
  }
  return result;
}

bool ColorNameDatabase::hasColor(const QString& name) const {
  return m_nameCache.contains(name);
}

QString ColorNameDatabase::name(const QColor& c) const {
  auto keys = m_providers.keys();
  std::reverse(keys.begin(), keys.end());
  for (const auto& key : std::as_const(keys)) {
    auto n = m_providers.value(key)->name(encode(c));
    if (n.has_value())
      return n.value();
  }
  return c.name();
}

QOOL_NS_END
