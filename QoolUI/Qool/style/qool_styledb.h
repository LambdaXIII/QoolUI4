#ifndef QOOL_STYLE_DB_H
#define QOOL_STYLE_DB_H

#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class StyleDB: public QObject {
  Q_OBJECT
  QML_ELEMENT

  QOOL_SIMPLE_SINGLETON_DECL(StyleDB)
public:
  ~StyleDB() = default;

  // QOOL_PROPERTY_READONLY_FOR_QOBJECT_DECL(QStringList, themes)
};

QOOL_NS_END

#endif // QOOL_STYLE_DB_H