#ifndef QOOL_LITERALS_H
#define QOOL_LITERALS_H

#include "qoolns.hpp"

#include <QObject>

#define QOOL_LITERALS_USED

QOOL_NS_BEGIN
namespace QoolLiterals {

Q_NAMESPACE

enum Positions {
  Center = 0,
  TopLeft,
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
  RightBottom
};
Q_ENUM_NS(Positions)

enum PopupDirections { Above = -1, Covered = 0, Below = 1 };
Q_ENUM_NS(PopupDirections)

} // namespace QoolLiterals
QOOL_NS_END

#endif // QOOL_LITERALS_H
