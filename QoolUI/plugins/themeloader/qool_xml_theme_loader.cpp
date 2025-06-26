#include "qool_xml_theme_loader.h"

#include "qool_xml_theme_loader_impl.h"
#include "qoolcommon/debug.hpp"

#include <QColor>
#include <QFileInfo>

QOOL_NS_BEGIN

XMLThemeLoader::XMLThemeLoader(const QString& filename)
  : m_pImpl(new XMLThemeLoaderImpl) {
  m_pImpl->load(filename);
}

XMLThemeLoader::~XMLThemeLoader() {
  delete m_pImpl;
  m_pImpl = nullptr;
}

QString XMLThemeLoader::name() const {
  if (m_pImpl->metadata.contains("name")) {
    const auto nameV = m_pImpl->metadata.value("name");
    if (nameV.type() == QVariant::String)
      return nameV.toString();
  }
  return QFileInfo(m_pImpl->filename).baseName();
}

const QVariantMap& XMLThemeLoader::metadata() const {
  return m_pImpl->metadata;
}

const QVariantMap& XMLThemeLoader::active() const {
  return m_pImpl->active;
}

const QVariantMap& XMLThemeLoader::inactive() const {
  return m_pImpl->inactive;
}

const QVariantMap& XMLThemeLoader::disabled() const {
  return m_pImpl->disabled;
}

void XMLThemeLoaderImpl::load(const QString& path) {
  QFile file(path);
  filename = path;
  if (! file.open(QIODevice::ReadOnly)) {
    xWarning << "Failed to open file:" << path;
    return;
  }

  QXmlStreamReader xml(&file);
  while (! xml.atEnd() and ! xml.hasError()) {
    bool res = xml.readNextStartElement();
    if (! res)
      continue;
    if (xml.name() == "qooltheme")
      load_metadata(xml);
    else if (xml.name() == "active")
      load_active(xml);
    else if (xml.name() == "inactive")
      load_inactive(xml);
    else if (xml.name() == "disabled")
      load_disabled(xml);
  }
  if (xml.hasError()) {
    xWarning << "Error parsing file:" << path << ":"
             << xml.errorString();
  }
}

void XMLThemeLoaderImpl::load_metadata(QXmlStreamReader& xml) {
  Q_ASSERT(xml.name() == "qooltheme");
  const auto& attr = xml.attributes();
  for (const auto& a : attr) {
    const auto aname = a.name();
    const auto avalue = a.value();
    // xInfo << xDBGToken("XMLThemeLoader") << aname << ":" << avalue;
    metadata.insert(aname.toString(), avalue.toString());
  }
}

void XMLThemeLoaderImpl::load_active(QXmlStreamReader& xml) {
  Q_ASSERT(xml.name() == "active");
  QList<PropertyNode> nodes;
  xml.readNextStartElement();
  while (xml.name() != "active") {
    if (! xml.readNextStartElement())
      continue;
    const auto node = load_property_node(xml);
    nodes.append(node);
  }
  auto result = resolve_property_nodes(nodes);
  xInfo << "Active Properties:" << xDBGMap(result);
  active.insert(result);
}

void XMLThemeLoaderImpl::load_inactive(QXmlStreamReader& xml) {
  Q_ASSERT(xml.name() == "inactive");
  QList<PropertyNode> nodes;
  xml.readNextStartElement();
  while (xml.name() != "inactive") {
    if (! xml.readNextStartElement())
      continue;
    const auto node = load_property_node(xml);
    nodes.append(node);
  }
  inactive.insert(resolve_property_nodes(nodes, active));
}

void XMLThemeLoaderImpl::load_disabled(QXmlStreamReader& xml) {
  Q_ASSERT(xml.name() == "disabled");
  QList<PropertyNode> nodes;
  xml.readNextStartElement();
  while (xml.name() != "disabled") {
    if (! xml.readNextStartElement())
      continue;
    const auto node = load_property_node(xml);
    nodes.append(node);
  }
  disabled.insert(resolve_property_nodes(nodes, active));
}

XMLThemeLoaderImpl::PropertyNode XMLThemeLoaderImpl::load_property_node(
  QXmlStreamReader& xml) {
  PropertyNode result;

  const auto tag = xml.name();
  const auto attrs = xml.attributes();

  result.type = tag.toString();

  if (attrs.hasAttribute("copy"))
    result.copy = attrs.value("copy").toString();
  if (attrs.hasAttribute("add"))
    result.add = attrs.value("add").toDouble();
  if (attrs.hasAttribute("multiply"))
    result.multiply = attrs.value("multiply").toDouble();
  if (attrs.hasAttribute("darker"))
    result.darker = attrs.value("darker").toDouble();
  if (attrs.hasAttribute("lighter"))
    result.lighter = attrs.value("lighter").toDouble();
  if (attrs.hasAttribute("prepend"))
    result.prepend = attrs.value("prepend").toString();
  if (attrs.hasAttribute("append"))
    result.append = attrs.value("append").toString();

  if (attrs.hasAttribute("property"))
    result.name = attrs.value("property").toString();

  const QStringView raw_value = attrs.hasAttribute("value") ?
                                  attrs.value("value") :
                                  xml.readElementText();

  if (tag == "color")
    result.value = QColor(raw_value.toString());
  if (tag == "number")
    result.value = raw_value.toDouble();
  if (tag == "string")
    result.value = raw_value.toString();

  static const QSet<QString> bool_tags { "true", "on", "yes" };
  if (tag == "bool")
    result.value = bool_tags.contains(raw_value.toString().toLower());

  if (tag == "list") {
    while (xml.name() != "list") {
      if (xml.readNextStartElement())
        result.values.append(load_property_node(xml));
    }
  }

  // xDebug << xDBGToken("XMLThemeLoader") << tag << ":" << raw_value;
  return result;
}

QVariantMap XMLThemeLoaderImpl::resolve_property_nodes(
  const QList<PropertyNode>& nodes, const QVariantMap& dependencies) {
  QVariantMap result;

  static const auto has_ref_value = [&](const QString& key) {
    return result.contains(key) || dependencies.contains(key);
  };
  static const auto get_ref_value = [&](const QString& key) {
    if (result.contains(key))
      return result.value(key);
    return dependencies.value(key);
  };

  QList<PropertyNode> list_nodes;
  QMap<QString, PropertyNode> complex_nodes;
  for (auto& node : nodes) {
    if (node.type == "list")
      list_nodes.append(node);
    else if (node.copy.has_value())
      complex_nodes.insert(node.name, node);
    else
      result.insert(node.name, node.value);
  }

  auto names = sorted_property_nodes(complex_nodes);
  while (! complex_nodes.isEmpty()) {
    for (int i = 0; i < names.length(); i++) {
      const auto name = names.takeFirst();
      const auto& node = complex_nodes.value(name);
      const auto copy = node.copy.value();
      if (! has_ref_value(copy)) {
        names.append(name);
        continue;
      }
      const QVariant ref_value = get_ref_value(copy);
      const QVariant value = process_value(node, ref_value);
      result.insert(name, value);
    } // for
  } // while
  if (! names.isEmpty()) {
    xWarning << "Circular reference detected:" << names;
  }

  for (const auto& node : std::as_const(list_nodes)) {
    QVariantList values;
    std::transform(node.values.constBegin(), node.values.constEnd(),
      std::back_inserter(values), [&](const PropertyNode& p) {
        QVariant v = p.value;
        if (p.copy.has_value()) {
          auto copy = p.copy.value();
          if (has_ref_value(copy))
            v = get_ref_value(copy);
        }
        v = process_value(p, v);
        return v;
      });
    values.removeIf([](const QVariant& v) { return v.isNull(); });
    result.insert(node.name, values);
  } // for list_nodes

  return result;
}

QVariant XMLThemeLoaderImpl::process_value(
  const PropertyNode& node, const QVariant& ref_value) {
  QVariant source = node.value;
  if (! ref_value.isNull())
    source = ref_value;

  if (node.type == "color") {
    QColor v = source.value<QColor>();
    if (node.darker.has_value())
      v = v.darker(node.darker.value() * 100);
    if (node.lighter.has_value())
      v = v.lighter(node.lighter.value() * 100);
    return QVariant::fromValue(v);
  }

  if (node.type == "number") {
    qreal v = source.value<qreal>();
    if (node.multiply.has_value())
      v *= node.multiply.value();
    if (node.add.has_value())
      v += node.add.value();
    return QVariant::fromValue(v);
  }

  if (node.type == "string") {
    auto v = source.toString();
    if (node.append.has_value())
      v.append(node.append.value());
    if (node.prepend.has_value())
      v.prepend(node.prepend.value());
    return QVariant::fromValue(v);
  }

  return source;
}

QStringList XMLThemeLoaderImpl::sorted_property_nodes(
  const QMap<QString, XMLThemeLoaderImpl::PropertyNode>& nodes) {
  QMap<QString, int> depths;
  int cycle = 0;
  QStringList keys = nodes.keys();
  while (cycle < 20 && ! keys.isEmpty()) {
    for (int i = 0; i < keys.length(); i++) {
      const QString k = keys.takeFirst();
      const PropertyNode& node = nodes[k];
      if (node.copy.has_value()) {
        const auto copy = node.copy.value();
        if (depths.contains(copy))
          depths[k] = depths[copy] + 1;
        else
          keys.append(k);
      } else {
        depths[k] = 0;
      }
    } // for
  } // while
  if (! keys.isEmpty()) {
    qWarning() << "Cyclic dependency detected:" << keys
               << "will try to solve them later.";
  }

  static const auto sort_function = [&](const QString& k1,
                                      const QString& k2) {
    static const int max_depth = 999999999;
    const auto n1 = depths.value(k1, max_depth);
    const auto n2 = depths.value(k2, max_depth);
    return n1 < n2;
  };

  keys = nodes.keys();
  std::stable_sort(keys.begin(), keys.end(), sort_function);
  return keys;
}

bool XMLThemeLoader::isValid() const {
  if (m_pImpl->active.isEmpty())
    return false;
  if (m_pImpl->inactive.isEmpty())
    return false;
  if (m_pImpl->disabled.isEmpty())
    return false;
  return true;
}

QString XMLThemeLoader::filename() const {
  return m_pImpl->filename;
}

QOOL_NS_END
