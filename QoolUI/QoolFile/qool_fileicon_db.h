#ifndef QOOL_FILEICON_DB_H
#define QOOL_FILEICON_DB_H

#include "qool_interface_fileiconprovider.h"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QSize>

QOOL_NS_BEGIN

class FileIconDB: public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  QOOL_SIMPLE_SINGLETON_DECL(FileIconDB)
  QOOL_SIMPLE_SINGLETON_QML_CREATE(FileIconDB)

public:
  ~FileIconDB();

  QString requestPath(QAnyStringView id, const QSize& size = {}) const;
  QUrl requrestUrl(QAnyStringView id, const QSize& size = {}) const;

  Q_INVOKABLE QUrl iconUrl(const QUrl& fileUrl) const;

protected:
  QMap<qreal, FileIconProvider*> m_providers;
  void auto_install_providers();
};

QOOL_NS_END

#endif // QOOL_FILEICON_DB_H
