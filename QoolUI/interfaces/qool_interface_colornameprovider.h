#ifndef QOOL_INTERFACE_COLORNAMEPROVIDER_H
#define QOOL_INTERFACE_COLORNAMEPROVIDER_H

#include "qoolns.hpp"

#include <array>
#include <optional>
#include <QtPlugin>

QOOL_NS_BEGIN

// 颜色名提供插件接口（插件契约见 qool-plugin-interfaces 页面）。
// 提供「名称 ↔ RGBA」双向查询；优先级统一由插件 json 元数据的
// priority 字段定义（PluginLoader 读取），本接口刻意不提供
// priority() 方法——防止实现方绕过元数据裁决。
struct ColorNameProvider {
  // 轻量 RGBA 表示（0..1 浮点），刻意避免引入 QtGui 依赖。
  using QoolRGBA = std::array<qreal, 4>;

  virtual ~ColorNameProvider() = default;

  virtual QString category() const = 0;
  virtual QStringList names() const = 0;
  virtual std::optional<QoolRGBA> color(const QString& name) const = 0;
  virtual std::optional<QString> name(const QoolRGBA& rgba) const = 0;
};

QOOL_NS_END

#define QOOL_COLORNAMEPROVIDER_IID                                    \
  "com.qoolui.colornameprovider.interface"

Q_DECLARE_INTERFACE(
  QOOL_NS::ColorNameProvider, QOOL_COLORNAMEPROVIDER_IID)

#endif // QOOL_INTERFACE_COLORNAMEPROVIDER_H
