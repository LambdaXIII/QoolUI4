#ifndef QOOL_COLORNAMEDATABASE_H
#define QOOL_COLORNAMEDATABASE_H

#include "qool_interface_colornameprovider.h"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QMap>
#include <QObject>
#include <QQmlEngine>
#include <QSet>

QOOL_NS_BEGIN

class ColorNameDatabase: public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(ColorDB)
  QML_SINGLETON
  QOOL_SIMPLE_SINGLETON_DECL(ColorNameDatabase)
  QOOL_SIMPLE_SINGLETON_QML_CREATE(ColorNameDatabase)

protected:
  QMap<qreal, ColorNameProvider*> m_providers;
  QSet<QString> m_nameCache;
  void installPlugins();

  static QColor decode(std::optional<ColorNameProvider::QoolRGBA> rgba);
  static ColorNameProvider::QoolRGBA encode(const QColor& c);

public:
  ~ColorNameDatabase();

  Q_INVOKABLE QStringList names(const QString& category = {}) const;
  Q_INVOKABLE QColor color(
    const QString& name, const QColor& def = Qt::white) const;
  Q_INVOKABLE QStringList categories() const;
  Q_INVOKABLE bool hasColor(const QString& name) const;
  Q_INVOKABLE QString name(const QColor& color) const;
};

QOOL_NS_END

#endif // QOOL_COLORNAMEDATABASE_H
