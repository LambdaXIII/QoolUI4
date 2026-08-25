#ifndef QOOL_COLORNAME_HQ_H
#define QOOL_COLORNAME_HQ_H

#include "qoolns.hpp"

#include "qool_colorliterals.h"
#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QStringList>

QOOL_NS_BEGIN

class ColorNameHQ: public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(ColorNameHQ)
  QML_EXTENDED(ColorLiterals)
  QML_SINGLETON

public:
  static ColorNameHQ* create(QQmlEngine* engine, QJSEngine*) {
    return new ColorNameHQ(engine);
  }

  Q_INVOKABLE QStringList colorNames(const QString& category = {}) const;
  Q_INVOKABLE QColor color(
    const QString& name, const QColor& def = Qt::white) const;
  Q_INVOKABLE QStringList categories() const;
  Q_INVOKABLE bool isProvidedColorName(const QString& name) const;
  Q_INVOKABLE bool isValidColorName(const QString& name) const;
  Q_INVOKABLE QString colorName(const QColor& color) const;

private:
  explicit ColorNameHQ(QObject* parent = nullptr);
};

QOOL_NS_END

#endif // QOOL_COLORNAME_HQ_H
