#ifndef QOOL_XML_THEME_LOADER_IMPL_H
#define QOOL_XML_THEME_LOADER_IMPL_H

#include "qoolns.hpp"

#include <QDomElement>
#include <QString>
#include <QVariant>
#include <optional>

QOOL_NS_BEGIN

struct XMLThemeLoaderImpl {
  struct XProperty {
    QString name, type;
    QVariant value;
    QList<XProperty> values; // currently no use
    std::optional<QString> copy;
    std::optional<qreal> add, multiply, darker, lighter;
    std::optional<QString> prepend, append;
  };
  using XPropertyList = QList<XProperty>;
  using XPropertyMap = QMap<QString, XProperty>;

  QString filename;
  QVariantMap metadata, constants, active, inactive, disabled, custom;

  void load(const QString& filename);

private:
  static QVariantMap load_metadata(const QDomElement& e);
  static QVariantMap load_value_group(
    const QDomElement& e, const QVariantMap& refValues);

  static XProperty parse_property(const QDomElement& e);
  static QVariantMap solve_values(
    const XPropertyList& properties, const QVariantMap& refValues);
  static QVariant process_value(const XProperty& property,
    const std::optional<QVariant>& refValue = std::nullopt);
}; // Impl

QOOL_NS_END

#endif // QOOL_XML_THEME_LOADER_IMPL_H
