#ifndef QOOL_URLCHECKER_H
#define QOOL_URLCHECKER_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"

#include <QFileInfo>
#include <QObject>
#include <QQmlEngine>
#include <QRegularExpression>
#include <functional>

QOOL_NS_BEGIN

class UrlChecker: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit UrlChecker(QObject* parent = nullptr);

  Q_INVOKABLE bool isAcceptable(const QUrl& url) const;
  Q_INVOKABLE bool containsAcceptableUrls(
    const QList<QUrl>& urls) const;
  Q_INVOKABLE QList<QUrl> acceptableUrls(const QList<QUrl>& urls) const;

  enum PatternBehaviors {
    FullMatch,
    PatternIsRegex,
    PatternIsFileNameList,
    PatternIsSuffixList
  };
  Q_ENUM(PatternBehaviors)

protected:
  struct Impl;
  using Checker = std::function<bool(const QFileInfo&)>;
  QProperty<Checker> m_pathChecker;
  bool checkType(const QFileInfo& info) const;

  QBINDABLE_WRITABLE_PROPERTY(
    UrlChecker, QString, pattern)
  QBINDABLE_WRITABLE_PROPERTY(
    UrlChecker, PatternBehaviors, patternBehavior)
  QBINDABLE_WRITABLE_PROPERTY(
    UrlChecker, bool, acceptDirs)
  QBINDABLE_WRITABLE_PROPERTY(
    UrlChecker, bool, acceptFiles)
};

QOOL_NS_END

#endif // QOOL_URLCHECKER_H
