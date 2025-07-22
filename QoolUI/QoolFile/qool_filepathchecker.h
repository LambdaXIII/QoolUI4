#ifndef QOOL_FILEPATHCHECKER_H
#define QOOL_FILEPATHCHECKER_H

#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class FilePathChecker: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  enum PatternBehavior {
    FullMatchOnly,
    PatternIsSuffixList,
    PatternIsRegex,
    PatternIsFileNameList,
  };
  Q_ENUM(PatternBehavior)

  explicit FilePathChecker(QObject* parent = nullptr);
  ~FilePathChecker();

  Q_INVOKABLE bool check(const QUrl& url) const;
  Q_INVOKABLE bool containsAcceptableUrl(const QList<QUrl>& urls) const;
  Q_INVOKABLE QList<QUrl> acceptableUrls(const QList<QUrl>& urls) const;

protected:
  struct Impl;
  Impl* m_pImpl;

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(
    PatternBehavior, patternBehavior, PatternIsSuffixList)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(
    QString, pattern, QStringLiteral("*.*"));
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(bool, acceptFiles, true)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(bool, acceptDirs, true)
};

QOOL_NS_END

#endif // QOOL_FILEPATHCHECKER_H
