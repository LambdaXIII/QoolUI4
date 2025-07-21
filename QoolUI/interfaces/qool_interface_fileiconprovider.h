#ifndef QOOL_INTERFACE_FILEICONPROVIDER_H
#define QOOL_INTERFACE_FILEICONPROVIDER_H

#include "qoolns.hpp"

#include <QtPlugin>

QOOL_NS_BEGIN

struct FileIconProvider {
  virtual ~FileIconProvider() = default;
  virtual std::optional<QUrl> provideUrl(
    QAnyStringView id, const QSize& size) const = 0;
  virtual std::optional<QString> providePath(
    QAnyStringView id, const QSize& size) const = 0;
};

QOOL_NS_END

#define QOOL_FILEICONPROVIDER_IID                                      \
  "com.qoolui.fileiconprovider.interface"

Q_DECLARE_INTERFACE(
  QOOL_NS::FileIconProvider, QOOL_FILEICONPROVIDER_IID)

#endif // QOOL_INTERFACE_FILEICONPROVIDER_H
