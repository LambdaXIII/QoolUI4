#include "qool_qoolbox_settings.h"

QOOL_NS_BEGIN

QoolBoxSettings::QoolBoxSettings(QObject* parent)
  : QObject { parent } {

  QBINDABLE_SET_VALUE(offsetX, 0);
  QBINDABLE_SET_VALUE(offsetY, 0);
  QBINDABLE_SET_VALUE(borderWidth, 0);
  QBINDABLE_SET_VALUE(borderColor, Qt::red);
  QBINDABLE_SET_VALUE(fillColor, Qt::yellow);
  QBINDABLE_SET_VALUE(curved, false);

#define SIZE(X) bindable_cutSize##X().value()
  QBINDABLE_SET_BINDING(
      cutSpaceOnTop, [&] { return std::max(SIZE(TL), SIZE(TR)); });

  QBINDABLE_SET_BINDING(
      cutSpaceOnBottom, [&] { return std::max(SIZE(BL), SIZE(BR)); });

  QBINDABLE_SET_BINDING(
      cutSpaceOnLeft, [&] { return std::max(SIZE(TL), SIZE(BL)); });

  QBINDABLE_SET_BINDING(
      cutSpaceOnRight, [&] { return std::max(SIZE(TR), SIZE(BR)); });
#undef SIZE
}

QOOL_NS_END
