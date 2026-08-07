#ifndef QOOL_COLORNAMEPROVIDER_DEFAULT_H
#define QOOL_COLORNAMEPROVIDER_DEFAULT_H

#include "qool_interface_colornameprovider.h"
#include "qoolns.hpp"

#include <QHash>
#include <QtPlugin>

QOOL_NS_BEGIN

class DefaultColorNameProvider
  : public QObject
  , public QOOL_NS::ColorNameProvider {
  Q_OBJECT
  Q_PLUGIN_METADATA(IID QOOL_COLORNAMEPROVIDER_IID FILE
                        "qool_colornameprovider_default.json")
  Q_INTERFACES(QOOL_NS::ColorNameProvider)

private:
  QHash<QString, QoolRGBA> m_map;
  QHash<QString, QString> m_nameMap;

public:
  DefaultColorNameProvider();
  ~DefaultColorNameProvider() = default;

  // ColorNameProvider interface
public:
  QString category() const override;
  QStringList names() const override;
  std::optional<QoolRGBA> color(const QString& name) const override;
  std::optional<QString> name(const QoolRGBA& rgba) const override;
};

QOOL_NS_END

#endif // QOOL_COLORNAMEPROVIDER_DEFAULT_H
