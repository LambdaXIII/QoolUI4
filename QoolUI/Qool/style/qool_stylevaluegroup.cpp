#include "qool_stylevaluegroup.h"

#include "qool_styledb.h"

QOOL_NS_BEGIN

StyleValueGroup::StyleValueGroup(QObject* parent)
  : QObject { parent }
  , ThemeValueGroupInterface {}
  , m_intData { new QVariantMap } {
}

StyleValueGroup::~StyleValueGroup() {
  delete m_intData;
}

bool StyleValueGroup::contains(const QString& key) const {
  return data()->contains(key);
}

QVariant StyleValueGroup::value(
  const QString& key, const QVariant& defvalue) const {
  if (data()->contains(key))
    return data()->value(key);
  const auto any = StyleDB::instance()->anyValue(key);
  if (any.isNull())
    return defvalue;
  data()->insert(key, any);
  return any;
}

QOOL_NS_END
