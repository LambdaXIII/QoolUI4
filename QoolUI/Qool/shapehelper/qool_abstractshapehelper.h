#ifndef QOOL_ABSTRACTSHAPEHELPER_H
#define QOOL_ABSTRACTSHAPEHELPER_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolcommon/qoolns.hpp"

#include <QObject>
#include <QQuickItem>

QOOL_NS_BEGIN

class AbstractShapeHelper: public QObject {
  Q_OBJECT

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QQuickItem*, target)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(qreal, width)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(qreal, height)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QSizeF, size)

public:
  explicit AbstractShapeHelper(QObject* parent = nullptr);

  QOOL_MAKE_PROPERTY_BINDABLE(qreal, width)
  QOOL_MAKE_PROPERTY_BINDABLE(qreal, height)
  QOOL_MAKE_PROPERTY_BINDABLE(qreal, size)
  QOOL_MAKE_PROPERTY_BINDABLE(QQuickItem*, target)

private:
  QQuickItem* m_target { nullptr };
  QSizeF m_internalSize { 0, 0 };
};

QOOL_NS_END

#endif // QOOL_ABSTRACTSHAPEHELPER_H
