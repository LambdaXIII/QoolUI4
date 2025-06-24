#include "qool_xml_theme_loader.h"

#include "qoolcommon/debug.hpp"

#include <QCache>
#include <QColor>
#include <QFile>
#include <QFileInfo>
#include <QScopedPointer>
#include <QXmlStreamReader>
#include <optional>

QOOL_NS_BEGIN

struct XMLThemeLoaderImpl {
  struct XmlProperty {
    QString name, type;
    QVariant value;
    std::optional<QString> copy;
    std::optional<qreal> darker, lighter, multiply, add;
    std::optional<QString> append, prepend;
    QList<XmlProperty> values;
  };

  struct Theme {
    QVariantMap metadata, properties;
  };

  QScopedPointer<Theme> current_theme { new Theme };
  QXmlStreamReader xml;
  QString xmlPath;

  void loadTheme(const QString& path);
  static QVariantMap parseMetadata(QXmlStreamReader& xml);

  static XmlProperty parseColor(QXmlStreamReader& xml);
  static XmlProperty parseNumber(QXmlStreamReader& xml);
  static XmlProperty parseString(QXmlStreamReader& xml);
  static XmlProperty parseBool(QXmlStreamReader& xml);
  static XmlProperty parseList(QXmlStreamReader& xml);
  static XmlProperty parseAlias(QXmlStreamReader& xml);
  static XmlProperty parseProperty(QXmlStreamReader& xml);

  static void sortPropertiesByDepth(QList<XmlProperty>& properties);
  static QVariant processValue(
    const XmlProperty& property, QVariant refValue);
  static QVariantMap resolveProperties(
    const QList<XmlProperty>& properties);
}; // Impl

void XMLThemeLoaderImpl::loadTheme(const QString& path) {
  xmlPath = path;
  current_theme.reset(new Theme);

  QFile file(path);
  if (! file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    xDebug << xDBGToken("XMLThemeLoader")
           << "Failed to open theme file: " << path;
    return;
  }
  xml.setDevice(&file);
  QList<XmlProperty> properties;

  while (! xml.atEnd() && ! xml.hasError()) {
    xml.readNext();
    if (! xml.isStartElement())
      continue;
    const auto tag = xml.name();
    if (tag == "qooltheme")
      current_theme->metadata = parseMetadata(xml);
    else
      properties << parseProperty(xml);
  }

  current_theme->properties = resolveProperties(properties);
  xDebug << xDBGToken("XMLThemeLoader") << "Theme loaded:" << path;
  xDebug << xDBGToken("XMLThemeLoader")
         << "Metadata:" << xDBGMap(current_theme->metadata);
  xDebug << xDBGToken("XMLThemeLoader")
         << "Properties:" << xDBGMap(current_theme->properties);
}

QVariantMap XMLThemeLoaderImpl::parseMetadata(QXmlStreamReader& xml) {
  QVariantMap result;
  const auto& attrs = xml.attributes();
  for (int i = 0; i < attrs.size(); ++i) {
    const auto& attr = attrs.at(i);
    result.insert(attr.name().toString(), attr.value().toString());
  }
  return result;
}

XMLThemeLoaderImpl::XmlProperty XMLThemeLoaderImpl::parseColor(
  QXmlStreamReader& xml) {
  XmlProperty result;
  result.type = "color";
  if (xml.attributes().hasAttribute("property"))
    result.name = xml.attributes().value("property").toString();
  if (xml.attributes().hasAttribute("copy"))
    result.copy = xml.attributes().value("copy").toString();
  if (xml.attributes().hasAttribute("darker"))
    result.darker = xml.attributes().value("darker").toDouble();
  if (xml.attributes().hasAttribute("lighter"))
    result.lighter = xml.attributes().value("lighter").toDouble();

  const auto value_t = xml.attributes().hasAttribute("value") ?
                         xml.attributes().value("value").toString() :
                         xml.readElementText();
  if (! value_t.isEmpty())
    result.value = QColor(value_t);
  return result;
}

XMLThemeLoaderImpl::XmlProperty XMLThemeLoaderImpl::parseNumber(
  QXmlStreamReader& xml) {
  XmlProperty result;
  result.type = "number";
  if (xml.attributes().hasAttribute("property"))
    result.name = xml.attributes().value("property").toString();
  if (xml.attributes().hasAttribute("copy"))
    result.copy = xml.attributes().value("copy").toString();
  if (xml.attributes().hasAttribute("multiply"))
    result.multiply = xml.attributes().value("multiply").toDouble();
  if (xml.attributes().hasAttribute("add"))
    result.add = xml.attributes().value("add").toDouble();
  const auto value_t = xml.attributes().hasAttribute("value") ?
                         xml.attributes().value("value").toString() :
                         xml.readElementText();
  if (! value_t.isEmpty())
    result.value = value_t.toDouble();
  return result;
}

XMLThemeLoaderImpl::XmlProperty XMLThemeLoaderImpl::parseString(
  QXmlStreamReader& xml) {
  XmlProperty result;
  result.type = "string";
  if (xml.attributes().hasAttribute("property"))
    result.name = xml.attributes().value("property").toString();
  if (xml.attributes().hasAttribute("copy"))
    result.copy = xml.attributes().value("copy").toString();
  if (xml.attributes().hasAttribute("append"))
    result.append = xml.attributes().value("append").toString();
  if (xml.attributes().hasAttribute("prepend"))
    result.prepend = xml.attributes().value("prepend").toString();

  const auto value_t = xml.attributes().hasAttribute("value") ?
                         xml.attributes().value("value").toString() :
                         xml.readElementText();
  if (! value_t.isEmpty())
    result.value = value_t;
  return result;
}

XMLThemeLoaderImpl::XmlProperty XMLThemeLoaderImpl::parseAlias(
  QXmlStreamReader& xml) {
  XmlProperty result;
  result.type = "alias";
  if (xml.attributes().hasAttribute("property"))
    result.name = xml.attributes().value("property").toString();
  if (xml.attributes().hasAttribute("copy"))
    result.copy = xml.attributes().value("copy").toString();
  return result;
}

XMLThemeLoaderImpl::XmlProperty XMLThemeLoaderImpl::parseList(
  QXmlStreamReader& xml) {
  XmlProperty result;
  result.type = "list";
  if (xml.attributes().hasAttribute("property"))
    result.name = xml.attributes().value("property").toString();
  if (xml.attributes().hasAttribute("copy"))
    result.copy = xml.attributes().value("copy").toString();
  if (xml.attributes().hasAttribute("append"))
    result.append = xml.attributes().value("append").toString();
  if (xml.attributes().hasAttribute("prepend"))
    result.prepend = xml.attributes().value("prepend").toString();

  while (xml.readNextStartElement()) {
    result.values << parseProperty(xml);
  }

  return result;
}

XMLThemeLoaderImpl::XmlProperty XMLThemeLoaderImpl::parseBool(
  QXmlStreamReader& xml) {
  XmlProperty result;
  result.type = "bool";
  if (xml.attributes().hasAttribute("property"))
    result.name = xml.attributes().value("property").toString();
  if (xml.attributes().hasAttribute("copy"))
    result.copy = xml.attributes().value("copy").toString();

  const QString value_t =
    xml.attributes().hasAttribute("value") ?
      xml.attributes().value("value").toString().toLower() :
      xml.readElementText().toLower();
  static const QStringList yes_values { "true", "yes", "on" };
  result.value = yes_values.contains(value_t);
  return result;
}

XMLThemeLoaderImpl::XmlProperty XMLThemeLoaderImpl::parseProperty(
  QXmlStreamReader& xml) {
  const auto tag = xml.name();
  if (tag == "bool")
    return parseBool(xml);
  else if (tag == "color")
    return parseColor(xml);
  else if (tag == "number")
    return parseNumber(xml);
  else if (tag == "string")
    return parseString(xml);
  else if (tag == "list")
    return parseList(xml);
  return {};
}

QVariantMap XMLThemeLoaderImpl::resolveProperties(
  const QList<XmlProperty>& properties) {
  QVariantMap result;

  // PreProcess properties
  QList<XmlProperty> alias_properties, list_properties,
    normal_properties;
  for (const auto& property : properties) {
    if (property.type == "alias")
      alias_properties << property;
    else if (property.type == "list")
      list_properties << property;
    else
      normal_properties << property;
  }

  sortPropertiesByDepth(normal_properties);
  for (const auto& p : std::as_const(normal_properties)) {
    QVariant baseValue = p.value;
    if (p.copy.has_value())
      baseValue = result[p.copy.value()];
    result.insert(p.name, processValue(p, baseValue));
  }

  for (const auto& p : std::as_const(list_properties)) {
    QVariantList list;
    for (const auto& pv : std::as_const(p.values)) {
      QVariant baseValue = pv.value;
      if (pv.copy.has_value())
        baseValue = result[pv.copy.value()];
      list.append(processValue(pv, baseValue));
    }
    result.insert(p.name, list);
  }

  for (const auto& p : std::as_const(alias_properties)) {
    if (p.copy.has_value())
      result.insert(p.name, result[p.copy.value()]);
  }

  if (result.contains(""))
    xWarning
      << xDBGToken("XMLThemeLoader")
      << "Empty property names found in theme, might be a mistake.";

  return result;
}

void XMLThemeLoaderImpl::sortPropertiesByDepth(
  QList<XMLThemeLoaderImpl::XmlProperty>& properties) {
  QMap<QString, int> depths {};
  QMap<QString, XmlProperty> indexes;
  for (const auto& p : std::as_const(properties))
    indexes.insert(p.name, p);

  QStringList names = indexes.keys();
  int cycles = 0;
  while (cycles < 20 && ! names.isEmpty()) {
    for (int i = 0; i < names.length(); ++i) {
      const auto name = names.takeFirst();
      const auto& property = indexes[name];
      if (property.copy.has_value()) {
        auto ref_name = property.copy.value();
        if (depths.contains(ref_name))
          depths.insert(name, depths[ref_name] + 1);
        else
          names.append(name);
      } else {
        depths.insert(name, 0);
      }
    } // for
  } // while

  std::stable_sort(properties.begin(), properties.end(),
    [&](const XmlProperty& a, const XmlProperty& b) {
      const int da = depths.value(a.name, 9999999);
      const int db = depths.value(b.name, 9999999);
      return da < db;
    });
}

QVariant XMLThemeLoaderImpl::processValue(
  const XMLThemeLoaderImpl::XmlProperty& property, QVariant refValue) {
  if (property.type == "color") {
    QColor v = refValue.value<QColor>();
    if (property.darker.has_value())
      v = v.darker(property.darker.value() * 100);
    if (property.lighter.has_value())
      v = v.lighter(property.lighter.value() * 100);
    return QVariant::fromValue(v);
  }

  if (property.type == "number") {
    qreal number = refValue.toDouble();
    if (property.add.has_value())
      number += property.add.value();
    if (property.multiply.has_value())
      number *= property.multiply.value();
    return QVariant::fromValue(number);
  }

  if (property.type == "string") {
    QString str = refValue.toString();
    if (property.append.has_value())
      str += property.append.value();
    if (property.prepend.has_value())
      str.prepend(property.prepend.value());
    return QVariant::fromValue(str);
  }

  return refValue;
}

XMLThemeLoader::XMLThemeLoader(const QString& xmlPath)
  : m_pImpl { new XMLThemeLoaderImpl } {
  m_pImpl->loadTheme(xmlPath);
}

XMLThemeLoader::~XMLThemeLoader() {
  if (m_pImpl)
    delete m_pImpl;
  m_pImpl = nullptr;
}

QString XMLThemeLoader::name() const {
  const auto& m = m_pImpl->current_theme->metadata;
  if (m.contains("name"))
    return m.value("name").toString();
  return QFileInfo(m_pImpl->xmlPath).baseName();
}

const QVariantMap& XMLThemeLoader::theme() const {
  return m_pImpl->current_theme->properties;
}

const QVariantMap& XMLThemeLoader::metadata() const {
  return m_pImpl->current_theme->metadata;
}

QOOL_NS_END
