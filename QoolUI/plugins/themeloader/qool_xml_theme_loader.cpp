#include "qool_xml_theme_loader.h"

#include "qoolcommon/debug.hpp"

#include <QColor>
#include <QFile>
#include <QXmlStreamReader>

QOOL_NS_BEGIN

struct XmlProperty {
  QString type;
  QString name;
  QVariant value;
  QString copy;
  qreal plus, times, darker, lighter;
};

QVariant parse_value(const QXmlStreamReader& reader) {
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
  while (true) {
    reader.readNext();
    if (reader.isEndDocument() && reader.name() == "list")
      break;
    if (! reader.isStartDocument())
      continue;
    QVariant item = parse_value(reader);
    if (item.isNull())
      continue;
    result << item;
  }
  return result;
}

XmlProperty from_reader(QXmlStreamReader& reader) {
  XmlProperty result;

  result.type = reader.name().toString();
  const auto& attrs = reader.attributes();
  result.name = attrs.value("property").toString();

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
  // while (!reader.atEnd() && !reader.hasError()) {
  //     reader.readNext();
  for (; ! reader.atEnd() and ! reader.hasError(); reader.readNext()) {
    if (! reader.isStartElement())
      continue;

    const auto attrs = reader.attributes();

    if (! attrs.hasAttribute("property")) {
      xWarning << xDBGToken("XMLThemeLoader")
               << QString(
                    "Node on line %1 does not have property attribute")
                    .arg(reader.lineNumber());
      continue;
    }

    XmlProperty xmlProperty;
    xmlProperty.type = reader.name().toString();
    xmlProperty.name = attrs.value("property").toString();

    if (xmlProperty.type == "color")

      results.insert(xmlProperty.name, xmlProperty);
  } // while reader
  return results;
}

QOOL_NS_END