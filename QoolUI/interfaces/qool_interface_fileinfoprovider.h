#ifndef QOOL_INTERFACE_FILEINFOPROVIDER_H
#define QOOL_INTERFACE_FILEINFOPROVIDER_H

#include "qoolns.hpp"

#include <QUrl>
#include <QVariantMap>
#include <QtPlugin>

QOOL_NS_BEGIN

struct FileInfoProvider {
  virtual ~FileInfoProvider() = default;
  virtual bool canProvide(const QUrl&) const = 0;
  virtual QVariantMap provide(const QUrl&) const = 0;
};

QOOL_NS_END

#define QOOL_FILEINFOPROVIDER_IID                                      \
  "com.qoolui.fileinfoprovider.interface"
Q_DECLARE_INTERFACE(
  QOOL_NS::FileInfoProvider, QOOL_FILEINFOPROVIDER_IID)

#endif // QOOL_INTERFACE_FILEINFOPROVIDER_H