#ifndef QOOL_ABSTRACTSHAPEHELPER_H
#define QOOL_ABSTRACTSHAPEHELPER_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/qoolns.hpp"

#include <QObject>
#include <QQuickItem>

QOOL_NS_BEGIN

class AbstractShapeHelper: public QObject {
  Q_OBJECT

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    AbstractShapeHelper, QQuickItem*, target)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    AbstractShapeHelper, qreal, width)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    AbstractShapeHelper, qreal, height)

public:
  explicit AbstractShapeHelper(QObject* parent = nullptr);
  virtual Q_INVOKABLE void dumpInfo() const;

private:
  Q_SLOT void resetSizeBindings();
};

QOOL_NS_END

#endif // QOOL_ABSTRACTSHAPEHELPER_H
