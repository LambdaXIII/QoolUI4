#include "qool_colornameprovider_default.h"

#include <QColor>

QOOL_NS_BEGIN

DefaultColorNameProvider::DefaultColorNameProvider()
  : QObject { nullptr }
  , ColorNameProvider() {
  const auto colorNames = QColor::colorNames();
  for (const QString& n : colorNames) {
    auto c = QColor::fromString(n);
    QoolRGBA rgba { c.redF(), c.greenF(), c.blueF(), c.alphaF() };
    m_map.insert(n, rgba);
    m_nameMap.insert(c.name(QColor::HexArgb), n);
  }
}

QString DefaultColorNameProvider::category() const {
  return "DEFAULT";
}

QStringList DefaultColorNameProvider::names() const {
  return m_map.keys();
}

std::optional<ColorNameProvider::QoolRGBA>
  DefaultColorNameProvider::color(const QString& name) const {
  if (! m_map.contains(name))
    return {};
  return m_map.value(name);
}

std::optional<QString> DefaultColorNameProvider::name(
  const QoolRGBA& rgba) const {
  QColor c =
    QColor::fromRgbF(rgba.at(0), rgba.at(1), rgba.at(2), rgba.at(3));
  auto code = c.name(QColor::HexArgb);
  if (! m_nameMap.contains(code))
    return {};
  return m_nameMap.value(code);
}

QOOL_NS_END
