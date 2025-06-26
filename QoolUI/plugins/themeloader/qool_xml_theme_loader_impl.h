#ifndef QOOL_XML_THEME_LOADER_IMPL_H
#define QOOL_XML_THEME_LOADER_IMPL_H

#include "qoolns.hpp"

#include <QString>
#include <QVariant>
#include <QXmlStreamReader>
#include <optional>

QOOL_NS_BEGIN

struct XMLThemeLoaderImpl {
  struct PropertyNode {
    QString name, type;
    QVariant value;
    QList<PropertyNode> values;
    std::optional<QString> copy;
    std::optional<qreal> add, multiply, darker, lighter;
    std::optional<QString> prepend, append;
  };

  QString filename;
  QVariantMap metadata, active, inactive, disabled;

  void load(const QString& filename);

private:
  void load_metadata(QXmlStreamReader& xml);
  void load_active(QXmlStreamReader& xml);
  void load_inactive(QXmlStreamReader& xml);
  void load_disabled(QXmlStreamReader& xml);

  static PropertyNode load_property_node(QXmlStreamReader& xml);
  static PropertyNode parse_list(QXmlStreamReader& xml);
  static PropertyNode parse_element(QXmlStreamReader& xml);

  static QVariantMap resolve_property_nodes(
    const QList<PropertyNode>& nodes,
    const QVariantMap& dependencies = {});
  static QStringList sorted_property_nodes(
    const QMap<QString, PropertyNode>& nodes);
  static QVariant process_value(
    const PropertyNode& node, const QVariant& refValue = {});
}; // Impl

QOOL_NS_END

#endif // QOOL_XML_THEME_LOADER_IMPL_H
