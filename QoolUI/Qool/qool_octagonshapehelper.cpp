#include "qool_octagonshapehelper.h"

#include "qoolcommon/number_utils.hpp"

QOOL_NS_BEGIN

OctagonShapeHelper::OctagonShapeHelper(QObject* parent)
  : ShapeHelperBasic { parent } {
  QOOL_BINDABLE_PROPERTY_INIT_VALUE(cutSizeTL, 0);
  QOOL_BINDABLE_PROPERTY_INIT_VALUE(cutSizeTR, 0);
  QOOL_BINDABLE_PROPERTY_INIT_VALUE(cutSizeBL, 0);
  QOOL_BINDABLE_PROPERTY_INIT_VALUE(cutSizeBR, 0);
}

QOOL_NS_END
