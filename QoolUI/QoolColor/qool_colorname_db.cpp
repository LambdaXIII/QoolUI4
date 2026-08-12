#include "qool_colorname_db.h"

#include "qoolcommon/debug.hpp"
#include "qoolcommon/plugin_loader.hpp"

#include <algorithm>

QOOL_NS_BEGIN

// 颜色名数据库（进程级 C++ 单例）。查询语义（provider 裁决/名称缓存）
// 见 ColorNameHQ 的 QML 文档——本类只承载数据与查询逻辑，QML 面由
// ColorNameHQ 转发。单线程契约：本类无跨线程访问（插件安装与查询均
// 主线程），不额外加锁。
QOOL_SIMPLE_SINGLETON_QT_IMPL(ColorNameDB)

void ColorNameDB::installPlugins() {
  PriorityFixer pFixer;
  auto plugins = PluginLoader<ColorNameProvider>::loadInstances();
  if (plugins.isEmpty()) {
    xWarningQ << "No ColorNameProvider plugin detected. ColorNameDB has no "
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

QColor ColorNameDB::decode(
  std::optional<ColorNameProvider::QoolRGBA> rgba) {
  QColor result = Qt::black;
  if (rgba.has_value()) {
    auto v = rgba.value();
    result = QColor::fromRgbF(v.at(0), v.at(1), v.at(2), v.at(3));
  }
  return result;
}

ColorNameProvider::QoolRGBA ColorNameDB::encode(const QColor& c) {
  return { c.redF(), c.greenF(), c.blueF(), c.alphaF() };
}

ColorNameDB::ColorNameDB()
  : QObject { nullptr } {
  installPlugins();
  xInfoQ << "initialized with" << m_providers.count() << "providers.";
}

ColorNameDB::~ColorNameDB() {
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

QStringList ColorNameDB::names(const QString& category) const {
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

QColor ColorNameDB::color(
  const QString& name, const QColor& def) const {
  // 升序遍历：priority 小的 provider 先查询，首个命中胜出
  //（"补充"型裁决：低数值 provider 提供基础色名，高数值仅补充未覆盖的查询）。
  for (auto* provider : m_providers) {
    auto c = provider->color(name);
    if (c)
      return decode(c);
  }
  return def;
}

QStringList ColorNameDB::categories() const {
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

bool ColorNameDB::hasColor(const QString& name) const {
  return m_nameCache.contains(name);
}

QString ColorNameDB::name(const QColor& c) const {
  for (auto* p : m_providers) {
    auto n = p->name(encode(c));
    if (n.has_value())
      return n.value();
  }
  return c.name();
}

QOOL_NS_END
