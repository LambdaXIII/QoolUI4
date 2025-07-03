#include "qool_style.h"

QOOL_NS_BEGIN

Style::Style(QObject* parent)
  : QQuickAttachedPropertyPropagator(parent) {
  initialize();
}

Style* Style::qmlAttachedPropertyes(QObject* object) {
  return new Style(object);
}

QOOL_NS_END
