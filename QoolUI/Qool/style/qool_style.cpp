#include "qool_style.h"

#include "qool_theme_database.h"
#include "qoolcommon/debug.hpp"

#include <QQuickWindow>

QOOL_NS_BEGIN

Style::Style(QObject* parent)
  : QQuickAttachedPropertyPropagator(parent) {
  initialize();
}

Style* Style::qmlAttachedProperties(QObject* object) {
  return new Style(object);
}

QOOL_NS_END
