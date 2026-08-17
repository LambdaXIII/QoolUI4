#include "qool_xml_theme_loader_impl.h"

#include "qoolcommon/debug.hpp"

#include <QColor>
#include <QDomDocument>
#include <QFile>
#include <QFileInfo>
#include <QScopedPointer>

// TODO: consider remove dependencies for Qt6::Xml

QOOL_NS_BEGIN

// 类：XMLThemeLoaderImpl
// XML 主题文件的解析实现：把分层主题段求解为五组 QVariantMap。
//
// `XMLThemeLoader`（门面）的 pimpl 实现体。`load()` 解析 XML 后填充
// `metadata`、`constants`、`active`、`inactive`、`disabled`、
// `custom` 六组映射，供门面只读暴露。
//
// 分层结构（刻意设计）
// 按 `constants` → `active/inactive/disabled/custom` 的顺序分层解析：
// `constants` 段最先加载，作为全局引用基准；其余四段以
// `constants` 叠加 `active` 的结果（refValues）为引用基准求解。
// `custom` 段独立保存，不再并入 `active`——历史实现误写入
// `active`，导致 custom 映射恒为空。
//
// copy 前向引用求解（刻意设计）
// `copy` 属性可引用同组内后声明的属性（前向引用）。`has_ref` 与
// `get_ref` 必须查询同一集合：只从已求解的 `result` 与 `refValues`
// 取值，若 `has_ref` 额外命中未求解的 copy 属性，前向引用会取到空值
// （如 `decorativeTextSize` copy toolTipTextSize 得 0.0）。copy 链经
// 多轮循环求解（上限为属性数的两倍），声明在前的属性先入 `result`，
// 后续轮次自然命中。
//
// name 兜底（刻意设计）
// `load()` 在开头与 `load_metadata` 整体覆盖后各补一次文件名基名：
// XML 根元素无 `name` 属性时，`metadata` 的 `name` 恒为
// `QFileInfo(filename).baseName()`，主题名始终可用。
//
// 值类型处理：`color`（`darker`/`lighter`）、`number`（`add`/
// `multiply`）、`string`（`prepend`/`append`）、`bool`（真值集为
// `yes`/`true`/`ok`，`"no"` 不在真值集）、`list` 与 `stringlist`
// 按元素求解。

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
  // 文件名兜底：load_metadata 整体覆盖 metadata，XML 根元素无 name
  // 属性时兜底丢失（name 恒为空）——补回
  if (! this->metadata.contains("name"))
    this->metadata.insert("name", QFileInfo(this->filename).baseName());

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
      // custom 段独立保存，不并入 active（custom 映射专为独立定制保留）
      this->custom.insert(loaded_values);
      continue;
    }

    this->metadata.insert(element.tagName(), element.text());
  } // for nodes

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
  result.type = "list";
  if (e.hasAttribute("property"))
    result.name = e.attribute("property");
  const auto nodes = e.childNodes();
  for (const auto& node : nodes) {
    const auto p = __decode_property__(node.toElement());
    result.values.append(p);
  }
  return result;
}

XMLThemeLoaderImpl::XProperty __decode_stringlist__(
  const QDomElement& e) {
  Q_ASSERT(e.tagName() == "stringlist");
  XMLThemeLoaderImpl::XProperty result;
  result.type = "stringlist";
  if (e.hasAttribute("property"))
    result.name = e.attribute("property");
  const auto nodes = e.childNodes();
  QStringList valueList;
  for (const auto& node : nodes) {
    valueList << node.toElement().text();
  }
  result.value = valueList;
  return result;
}

XMLThemeLoaderImpl::XProperty XMLThemeLoaderImpl::parse_property(
  const QDomElement& e) {
  if (e.tagName() == "stringlist")
    return __decode_stringlist__(e);

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

  // has_ref 与 get_ref 必须查同一集合：get_ref 只能从 result/refValues
  // 取值，has_ref 若额外命中 lazyProperties（尚未求解的 copy 属性），
  // 前向引用（B copy A，A 也是 copy）会取到空值（如 midnight.xml
  // decorativeTextSize copy toolTipTextSize 得 0.0）。copy 链由多轮
  // 循环求解：声明在前的属性先入 result，后续轮次自然命中。
  const auto has_ref = [&](const QString& name) {
    return result.contains(name) || refValues.contains(name);
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

  // "no" 不在真值集：原实现含 "no"，字符串 "no" 会被判定为 true
  static const QSet<QString> yes_tags { "yes", "true", "ok" };
  if (property.type == "bool") {
    QString t = value.toString().toLower();
    bool result = yes_tags.contains(t);
    return QVariant::fromValue<bool>(result);
  }

  return value;
}

QOOL_NS_END
