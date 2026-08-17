#include "qool_theme_hqmodel.h"

#include "qool_theme_db.h"

QOOL_NS_BEGIN

ThemeHQModel::ThemeHQModel(QObject* parent)
  : QIdentityProxyModel(parent) {
  setSourceModel(ThemeDB::instance());
}

QOOL_NS_END
