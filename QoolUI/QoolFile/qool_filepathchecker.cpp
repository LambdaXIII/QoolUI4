#include "qool_filepathchecker.h"

#include <QCache>
#include <QFileInfo>
#include <QMutex>
#include <QRegularExpression>

QOOL_NS_BEGIN

struct FilePathChecker::Impl {
  QCache<QByteArray, QRegularExpression> regexCache { 100 };

  QByteArray generateKey(const QString& pattern) {
    const auto mode = m_parent->m_patternBehavior;
    QByteArray result;
    result.append(mode);
    result.append(pattern.toUtf8());
    return result.toBase64(QByteArray::OmitTrailingEquals);
  }

  QRegularExpression generateSuffixList(const QString& pattern) {
    static const QRegularExpression headMarks("^[.*\\/]+");
    QString r = ".*(";
    const auto patterns = pattern.split(',', Qt::SkipEmptyParts);
    QStringList regex_subs;
    for (const auto& p : patterns) {
      auto a = p.simplified();
      a.remove(headMarks);
      regex_subs << a;
    }

    r.append((regex_subs.join('|')));
    r.append(")$");

    QRegularExpression result;
    result.setPattern(r);
    result.setPatternOptions(QRegularExpression::CaseInsensitiveOption);
    return result;
  }

  QRegularExpression generateFileNameList(const QString& pattern) {
    QString r = "^.*[/\\]?(";
    const QStringList names = pattern.split(',', Qt::SkipEmptyParts);
    r.append(names.join('|'));
    r.append(')');

    return QRegularExpression(
      r, QRegularExpression::CaseInsensitiveOption);
  }

  QRegularExpression generatePattern(const QString& pattern) {
    static const QRegularExpression ALL_PATTERN(".*");
    if (pattern.isEmpty())
      return ALL_PATTERN;

    const auto mode = m_parent->m_patternBehavior;

    switch (mode) {
    case PatternIsRegex:
      return QRegularExpression(pattern);
    case PatternIsSuffixList:
      return generateSuffixList(pattern);
    case PatternIsFileNameList:
      return generateFileNameList(pattern);
    default:
      break;
    }

    QString r = QString("^%1$").arg(pattern);
    return QRegularExpression(r);
  }

  QRegularExpression* regexFromPattern(const QString& pattern) {
    static QMutex mutex;
    const auto key = generateKey(pattern);
    if (! regexCache.contains(key)) {
      QMutexLocker locker(&mutex);
      if (! regexCache.contains(key)) {
        auto r = new QRegularExpression(generatePattern(pattern));
        regexCache.insert(key, r);
      }
    }

    return regexCache.object(key);
  }

  bool checkFileType(const QString& path) {
    const bool acceptFiles = m_parent->m_acceptFiles;
    const bool acceptDirs = m_parent->m_acceptDirs;
    if (! acceptFiles && ! acceptDirs)
      return false;
    const QFileInfo p(path);
    if (p.isDir() && ! acceptDirs)
      return false;
    if (p.isDir() && ! acceptFiles)
      return false;
    return true;
  }

  FilePathChecker* m_parent;
  Impl(FilePathChecker* p)
    : m_parent(p) {}
}; // Impl

FilePathChecker::FilePathChecker(QObject* parent)
  : QObject { parent }
  , m_pImpl { new Impl(this) } {
}

FilePathChecker::~FilePathChecker() {
  if (m_pImpl)
    delete m_pImpl;
  m_pImpl = nullptr;
}

bool FilePathChecker::check(const QUrl& url) const {
  if (url.isEmpty() || ! url.isValid())
    return false;
  const QString path = url.toString(QUrl::PreferLocalFile);
  if (! m_pImpl->checkFileType(path))
    return false;
  auto* regex = m_pImpl->regexFromPattern(m_pattern);
  return regex->match(path).hasMatch();
}

bool FilePathChecker::containsAcceptableUrl(
  const QList<QUrl>& urls) const {
  if (urls.isEmpty())
    return false;
  auto* regex = m_pImpl->regexFromPattern(m_pattern);
  for (const auto& url : urls) {
    const QString path = url.toString(QUrl::PreferLocalFile);
    if (! m_pImpl->checkFileType(path))
      continue;
    if (regex->match(path).hasMatch())
      return true;
  }
  return false;
}

QList<QUrl> FilePathChecker::acceptableUrls(
  const QList<QUrl>& urls) const {
  if (urls.isEmpty())
    return {};
  auto* regex = m_pImpl->regexFromPattern(m_pattern);

  const auto acceptable = [&](const QUrl& url) {
    const QString p = url.toString(QUrl::PreferLocalFile);
    const bool result =
      m_pImpl->checkFileType(p) && regex->match(p).hasMatch();
    return result;
  };

  QList<QUrl> results;
  std::copy_if(urls.cbegin(), urls.cend(), std::back_inserter(results),
    acceptable);
  return results;
}

QOOL_NS_END
