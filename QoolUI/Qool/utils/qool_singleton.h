#ifndef QOOL_SINGLETON_H
#define QOOL_SINGLETON_H

#include "qool_extension_positions.h"
#include "qool_geoutils.h"
#include "qool_literals.h"
#include "qool_smartobj.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolns.hpp"
#include "qoolversion.hpp"

QOOL_LITERALS_USED

QOOL_NS_BEGIN

class QoolSingleton: public SmartObject {
  Q_OBJECT
  QML_ELEMENT
  QML_EXTENDED_NAMESPACE(QoolLiterals)

  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(
    QString, version, QOOLUI_VERSION_FULL)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(
    Extension_Positions*, positions, nullptr)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(GeoUtils*, geo, nullptr)

public:
  explicit QoolSingleton(QObject* parent = nullptr);
  ~QoolSingleton() = default;

  Q_INVOKABLE void test();
};

QOOL_NS_END

#endif // QOOL_SINGLETON_H
