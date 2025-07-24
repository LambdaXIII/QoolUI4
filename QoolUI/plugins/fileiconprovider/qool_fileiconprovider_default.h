#ifndef QOOL_FILEICONPROVIDER_DEFAULT_H
#define QOOL_FILEICONPROVIDER_DEFAULT_H

#include "qool_interface_fileiconprovider.h"
#include "qoolns.hpp"

QOOL_NS_BEGIN

class FileIconProvider_Default
  : public QObject
  , public FileIconProvider {
  Q_OBJECT

  Q_PLUGIN_METADATA(IID QOOL_FILEICONPROVIDER_IID FILE
    "qool_fileiconprovider_default.json")
  Q_INTERFACES(QOOL_NS::FileIconProvider)

public:
  FileIconProvider_Default(QObject* parent = nullptr);
  ~FileIconProvider_Default();

  std::optional<QUrl> provideUrl(
    QAnyStringView id, const QSize& size) const override;
  std::optional<QString> providePath(
    QAnyStringView id, const QSize& size) const override;

protected:
  struct Impl;
  Impl* m_pImpl;
};

QOOL_NS_END

#endif // QOOL_FILEICONPROVIDER_DEFAULT_H