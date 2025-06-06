#ifndef QOOL_SHAPEHELPERBASIC_H
#define QOOL_SHAPEHELPERBASIC_H

#include "qoolcommon/qool_common.h"
#include "qoolcommon/qool_property.hpp"

#include <QObject>
#include <QObjectBindableProperty>
#include <QQuickItem>
#include <QSizeF>

QOOL_NS_BEGIN

class ShapeHelperBasic: public QObject {
  Q_OBJECT

  QOOL_PROPERTY(QQuickItem*, target, nullptr)
  QOOL_DECL_PROPERTY(QSizeF, size)
  QOOL_DECL_PROPERTY(qreal, width)
  QOOL_DECL_PROPERTY(qreal, height)

public:
  explicit ShapeHelperBasic(QObject* parent = nullptr);
  virtual ~ShapeHelperBasic() = default;

private:
  QSizeF m_internalSize;
};

QOOL_NS_END

#endif // QOOL_SHAPEHELPERBASIC_H
