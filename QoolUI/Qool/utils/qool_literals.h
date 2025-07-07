#ifndef QOOL_LITERALS_H
#define QOOL_LITERALS_H

#include "qoolns.hpp"

#include <QObject>

#define QOOL_LITERALS_USED

QOOL_NS_BEGIN
namespace QoolLiterals {

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

} // namespace QoolLiterals
QOOL_NS_END

#endif // QOOL_LITERALS_H
