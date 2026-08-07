#ifndef QOOL_COLORNAMEPROVIDER_COMMONZH_H
#define QOOL_COLORNAMEPROVIDER_COMMONZH_H

#include "qool_interface_colornameprovider.h"
#include "qoolns.hpp"

#include <QtPlugin>

QOOL_NS_BEGIN

class CommonZhColorNameProvider
  : public QObject
  , public QOOL_NS::ColorNameProvider {
  Q_OBJECT
  Q_PLUGIN_METADATA(IID QOOL_COLORNAMEPROVIDER_IID FILE
                        "qool_colornameprovider_commonzh.json")
  Q_INTERFACES(QOOL_NS::ColorNameProvider)

private:
  class Impl;
  Impl* m_impl { nullptr };

public:
  CommonZhColorNameProvider();
  ~CommonZhColorNameProvider();

  // ColorNameProvider interface
public:
  QString category() const override;
  QStringList names() const override;
  std::optional<QoolRGBA> color(const QString& name) const override;
  std::optional<QString> name(const QoolRGBA& rgba) const override;
};

QOOL_NS_END

#endif // QOOL_COLORNAMEPROVIDER_COMMONZH_H
