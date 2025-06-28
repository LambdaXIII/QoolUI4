#ifndef QOOL_FLAGS_H
#define QOOL_FLAGS_H

#include "QObject"
#include "qoolns.hpp"

QOOL_NS_BEGIN
namespace QoolFlags {

Q_NAMESPACE

enum Positions {
  TopLeft = 10,
  TopCenter,
  TopRight,
  LeftTop,
  LeftCenter,
  LeftBottom,
  BottomLeft,
  BottomCenter,
  BottomRight,
  RightTop,
  RightCenter,
  RightBottom,
  Center
};
Q_ENUM_NS(Positions)

} // namespace QoolFlags
QOOL_NS_END

#endif // QOOL_FLAGS_H
