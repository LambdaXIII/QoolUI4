#include "qool_xml_theme_loader_impl.h"

#include "qoolcommon/debug.hpp"

#include <QColor>
#include <QDomDocument>
#include <QFile>
#include <QFileInfo>
#include <QScopedPointer>
QOOL_NS_BEGIN

void XMLThemeLoaderImpl::load(const QString& filename) {
  this->filename = filename;
  this->metadata.insert("name", QFileInfo(this->filename).baseName());

  QFile file(filename);
  if (! file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    xWarning << xDBGToken("XMLThemeLoader")
             << "can't open file:" << xDBGRed << filename << xDBGReset;
    return;
  }

  QScopedPointer<QDomDocument> doc { new QDomDocument };
  const auto parsingResult = doc->setContent(&file);
  if (! parsingResult) {
    xWarning << xDBGToken("XMLThemeLoader") << xDBGRed
             << "Error occured parsing" << this->filename << "at"
             << xDBGYellow << parsingResult.errorLine << ":"
             << parsingResult.errorColumn << xDBGRed
             << parsingResult.errorMessage << xDBGReset;
    return;
  }

  const auto root = doc->documentElement();
  this->metadata = load_metadata(root);

  const auto nodes = root.childNodes();
  for (const auto& node : nodes) {
    const auto element = node.toElement();
    if (element.tagName() == "constants") {
      const auto loaded_values =
        load_value_group(element, this->constants);
      this->constants.insert(loaded_values);
      continue;
    }

    QVariantMap refValues = this->constants;
    refValues.insert(this->active);

    if (element.tagName() == "active") {
      const auto loaded_values = load_value_group(element, refValues);
      this->active.insert(loaded_values);
      continue;
    }
    if (element.tagName() == "inactive") {
      const auto loaded_values = load_value_group(element, refValues);
      this->inactive.insert(loaded_values);
      continue;
    }
    if (element.tagName() == "disabled") {
      const auto loaded_values = load_value_group(element, refValues);
      this->disabled.insert(loaded_values);
      continue;
    }
    if (element.tagName() == "custom") {
      const auto loaded_values = load_value_group(element, refValues);
      this->active.insert(loaded_values);
      continue;
    }

    this->metadata.insert(element.tagName(), element.text());
  } // for nodes

  // xDebug << "METADATA" << xDBGMap(metadata);
  // xDebug << "CONSTANTS" << xDBGMap(constants);
  // xDebug << "ACTIVE" << xDBGMap(active);
  // xDebug << "INACTIVE" << xDBGMap(inactive);
  // xDebug << "DISABLED" << xDBGMap(disabled);
  // xDebug << "CUSTOM" << xDBGMap(custom);

  xInfo << xDBGToken("XMLThemeLoader") << xDBGGreen << this->filename
        << xDBGReset << "parsing finished.";
}

QVariantMap XMLThemeLoaderImpl::load_metadata(const QDomElement& e) {
  QVariantMap result;
  const auto attrs = e.attributes();
  for (int i = 0; i < attrs.length(); ++i) {
    const auto attr = attrs.item(i).toAttr();
    result.insert(attr.name(), attr.value());
  }
  return result;
}

QVariantMap XMLThemeLoaderImpl::load_value_group(
  const QDomElement& e, const QVariantMap& refValues) {
  const auto child_nodes = e.childNodes();
  XPropertyList properties;
  std::transform(child_nodes.cbegin(), child_nodes.cend(),
    std::back_inserter(properties),
    [&](const QDomNode& node) -> XProperty {
      return parse_property(node.toElement());
    });
  QVariantMap result = solve_values(properties, refValues);
  return result;
}

XMLThemeLoaderImpl::XProperty __decode_property__(
  const QDomElement& e) {
  XMLThemeLoaderImpl::XProperty result;
  result.type = e.tagName();

  if (e.hasAttribute("property"))
    result.name = e.attribute("property");

  if (e.hasAttribute("copy"))
    result.copy = e.attribute("copy");

  if (e.hasAttribute("add"))
    result.add = e.attribute("add").toDouble();
  if (e.hasAttribute("multiply"))
    result.multiply = e.attribute("multiply").toDouble();
  if (e.hasAttribute("darker"))
    result.darker = e.attribute("darker").toDouble();
  if (e.hasAttribute("lighter"))
    result.lighter = e.attribute("lighter").toDouble();

  if (e.hasAttribute("prepend"))
    result.prepend = e.attribute("prepend");
  if (e.hasAttribute("append"))
    result.append = e.attribute("append");

  if (e.hasAttribute("value"))
    result.value = e.attribute("value");
  else
    result.value = e.text();

  return result;
}

XMLThemeLoaderImpl::XProperty __decode_list__(const QDomElement& e) {
  Q_ASSERT(e.tagName() == "list");
  XMLThemeLoaderImpl::XProperty result;
  if (e.hasAttribute("property"))
    result.name = e.attribute("property");
  const auto nodes = e.childNodes();
  for (const auto& node : nodes) {
    const auto p = __decode_property__(node.toElement());
    result.values.append(p);
  }
  return result;
}

XMLThemeLoaderImpl::XProperty XMLThemeLoaderImpl::parse_property(
  const QDomElement& e) {
  if (e.tagName() == "list")
    return __decode_list__(e);
  return __decode_property__(e);
}

QVariantMap XMLThemeLoaderImpl::solve_values(
  const XPropertyList& properties, const QVariantMap& refValues) {
  QVariantMap result;
  XPropertyMap lazyProperties, listProperties;
  for (const auto& p : properties) {
    if (p.name.isEmpty())
      continue;
    if (p.type == "list")
      listProperties.insert(p.name, p);
    else if (p.copy.has_value())
      lazyProperties.insert(p.name, p);
    else
      result.insert(p.name, process_value(p));
  }

  const auto has_ref = [&](const QString& name) {
    return result.contains(name) || lazyProperties.contains(name)
           || refValues.contains(name);
  };
  const auto get_ref = [&](const QString& name) -> QVariant {
    if (result.contains(name))
      return result.value(name);
    return refValues.value(name);
  };

  const int max_cycle = properties.length() * 2;
  int cycle = 1;
  QStringList processing_keys = lazyProperties.keys();
  while (! processing_keys.isEmpty() && cycle <= max_cycle) {
    for (int i = 0; i < processing_keys.length(); ++i) {
      const QString current_name = processing_keys.takeFirst();
      if (current_name.isEmpty())
        continue;
      const XProperty& current_property = lazyProperties[current_name];
      const QString copy_key = current_property.copy.value();
      if (! has_ref(copy_key)) {
        processing_keys.append(current_name);
        continue;
      }
      const auto ref_value = get_ref(copy_key);
      const auto current_value =
        process_value(current_property, ref_value);
      result.insert(current_name, current_value);
    } // for name in keys
    cycle++;
  } // cycle
  if (cycle < max_cycle)
    xInfo << xDBGToken("XMLThemeLoader") << "Properties solved in only"
          << xDBGYellow << cycle << xDBGReset << "cycles. Yay!";
  if (! processing_keys.isEmpty())
    xWarning << xDBGToken("XMLThemeLoader")
             << "Some keys were not processed after" << xDBGYellow
             << cycle << xDBGReset << "cycles:" << xDBGRed
             << processing_keys << xDBGReset;

  for (auto iter = listProperties.constBegin();
    iter != listProperties.constEnd();
    ++iter) {
    QVariantList list;
    const auto list_name = iter.key();
    const auto list_property = iter.value();
    for (const auto& current_property : list_property.values) {
      QVariant current_value;
      const auto copy = current_property.copy;
      if (copy.has_value() && has_ref(copy.value())) {
        current_value = get_ref(copy.value());
      } else {
        current_value = current_property.value;
      }
      current_value = process_value(current_property, current_value);
      list << current_value;
    } // element
    result.insert(list_name, list);
  } // list

  return result;
}

QVariant XMLThemeLoaderImpl::process_value(
  const XMLThemeLoaderImpl::XProperty& property,
  const std::optional<QVariant>& refValue) {
  QVariant value = property.value;
  if (refValue.has_value())
    value = refValue.value();

  if (property.type == "color") {
    QColor color = value.value<QColor>();
    if (property.darker.has_value())
      color = color.darker(property.darker.value() * 100);
    if (property.lighter.has_value())
      color = color.lighter(property.lighter.value() * 100);
    return QVariant::fromValue(color);
  }

  if (property.type == "number") {
    qreal number = value.toDouble();
    if (property.multiply.has_value())
      number *= property.multiply.value();
    if (property.add.has_value())
      number += property.add.value();
    return QVariant::fromValue(number);
  }

  if (property.type == "string") {
    QString text = value.toString();
    if (property.prepend.has_value())
      text.prepend(property.prepend.value());
    if (property.append.has_value())
      text.append(property.append.value());
    return QVariant::fromValue(text);
  }

  static const QSet<QString> yes_tags { "yes", "no", "true", "ok" };
  if (property.type == "bool") {
    QString t = value.toString().toLower();
    bool result = yes_tags.contains(t);
    return QVariant::fromValue<bool>(result);
  }

  return value;
}

QOOL_NS_END
