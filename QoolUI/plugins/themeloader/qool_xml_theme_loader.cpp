#include "qool_xml_theme_loader.h"

#include "qoolcommon/debug.hpp"

#include <QColor>
#include <QFile>
#include <QFileInfo>
#include <QXmlStreamReader>
#include <optional>

QOOL_NS_BEGIN

struct XmlProperty {
  QString type;
  QString name;
  std::optional<QVariant> value;
  std::optional<QString> copy;
  std::optional<qreal> plus, times, darker, lighter;
};

QVariant parse_value(QXmlStreamReader& reader) {
  const auto type = reader.name();
  const QXmlStreamAttributes& attrs = reader.attributes();
  const auto value_txt =
    attrs.hasAttribute("value") ?
      attrs.value("value") :
      reader.readElementText(QXmlStreamReader::SkipChildElements);

  if (value_txt.isEmpty())
    return {};

  if (type == "color")
    return { QColor(value_txt) };
  if (type == "int")
    return { value_txt.toInt() };
  if (type == "real")
    return { value_txt.toDouble() };
  if (type == "bool") {
    const auto v = value_txt.toString().toLower();
    return { v == "yes" || v == "true" || v == "on" };
  }
  if (type == "string")
    return { value_txt.toString() };

  return {};
}

QVariant parse_list(QXmlStreamReader& reader) {
  QVariantList result;
  while (reader.readNextStartElement()) {
    QVariant item = parse_value(reader);
    if (item.isNull())
      continue;
    result << item;
  }
  return { result };
}

XmlProperty from_reader(QXmlStreamReader& reader) {
  XmlProperty result;

  const auto& attrs = reader.attributes();
  result.name = attrs.value("property").toString();
  result.type = reader.name().toString();

  if (attrs.hasAttribute("copy"))
    result.copy = attrs.value("copy").toString();

  if (attrs.hasAttribute("plus"))
    result.plus = attrs.value("plus").toDouble();

  if (attrs.hasAttribute("times"))
    result.times = attrs.value("times").toDouble();

  if (attrs.hasAttribute("darker"))
    result.darker = attrs.value("darker").toDouble();

  if (attrs.hasAttribute("lighter"))
    result.lighter = attrs.value("lighter").toDouble();

  auto parsed_value = parse_value(reader);
  if (! parsed_value.isNull())
    result.value = parsed_value;

  return result;
}

using XmlProperties = QMap<QString, XmlProperty>;

XmlProperties parse_xml(const QString& xml) {
  QFile file(xml);
  if (! file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    return {};
  }

  XmlProperties results;

  QXmlStreamReader reader(&file);

  for (auto xmltoken = reader.tokenType();
    ! reader.atEnd() and ! reader.hasError();
    xmltoken = reader.readNext()) {
    if (xmltoken != QXmlStreamReader::StartElement)
      continue;

    const auto& attrs = reader.attributes();

    if (! attrs.hasAttribute("property")) {
      xWarning << xDBGToken("XMLThemeLoader")
               << QString(
                    "Node on line %1 does not have property attribute")
                    .arg(reader.lineNumber());
    }

    XmlProperty xmlProperty = from_reader(reader);
    if (! xmlProperty.name.isEmpty())
      results.insert(xmlProperty.name, xmlProperty);
  } // while reader
  return results;
}

QVariantMap resolve_properties(XmlProperties properties) {
  QVariantMap result;

  int cycle_count = 0;
  while (cycle_count < 20) {
    for (const auto& key : properties.keys()) {
      if (properties[key].value.has_value()) {
        result.insert(key, properties[key].value.value());
        properties.remove(key);
        continue;
      }
      const auto copy = properties[key].copy;
      if (! copy.has_value()) {
        properties.remove(key);
        xWarning << xDBGToken("XMLThemeLoader")
                 << QString("Property %1 does not have value or copy "
                            "attribute, will be ignored")
                      .arg(key);
        continue;
      }
      if (! result.contains(copy.value()))
        continue;

      const auto property = properties.take(key);
      const QVariant ref_value = result[copy.value()];
      if (property.type == "color") {
        QColor color = ref_value.value<QColor>();
        color = color.darker(property.darker.value_or(1.0) * 100);
        color = color.lighter(property.lighter.value_or(1.0) * 100);
        result[key] = QVariant::fromValue(color);
      } else if (property.type == "int") {
        int x = ref_value.value<int>();
        x += property.plus.value_or(0);
        x *= property.times.value_or(1.0);
        result[key] = QVariant::fromValue(x);
      } else if (property.type == "real") {
        double x = ref_value.value<double>();
        x += property.plus.value_or(0.0);
        x *= property.times.value_or(1.0);
        result[key] = QVariant::fromValue(x);
      } else {
        result[key] = ref_value;
      }
    } // for check

    if (properties.isEmpty())
      break;

    cycle_count++;
  } // while 20

  if (! properties.isEmpty()) {
    qWarning() << "20 parsing cycles reached and there still are "
                  "unsolvable properties:"
               << properties.keys();
  }
  xDebug << result;
  return result;
}

QVariantMap XMLThemeLoader::load(const QString& xml) {
  auto properties = parse_xml(xml);
  return resolve_properties(properties);
}

QString XMLThemeLoader::getThemeName(const QString& xml) {
  QString result = QFileInfo(xml).baseName();
  QFile file(xml);
  if (! file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    return result;
  }

  QXmlStreamReader reader(&file);
  for (auto i = reader.tokenType();
    ! reader.atEnd() && ! reader.hasError();
    i = reader.readNext()) {
    if (i != QXmlStreamReader::StartElement)
      continue;
    if (reader.name() == "qooltheme") {
      auto name = reader.attributes().value("name");
      if (! name.isEmpty())
        result = name.toString();
      break;
    }
  }

  return result;
}

QOOL_NS_END