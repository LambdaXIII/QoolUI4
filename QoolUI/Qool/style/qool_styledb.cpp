#include "qool_styledb.h"

#include <QMutex>

QOOL_NS_BEGIN

QOOL_SIMPLE_SINGLETON_QT_IMPL(StyleDB)
StyleDB::StyleDB()
  : QObject { nullptr } {
}

QOOL_NS_END