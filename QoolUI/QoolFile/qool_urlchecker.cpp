#include "qool_urlchecker.h"

#include <QCache>
#include <QFileInfo>

QOOL_NS_BEGIN

struct UrlChecker::Impl {
  static Checker make_fullmatch_checker(const QString& pattern) {
    Checker checker = [=](const QFileInfo& info) {
      const QString match = pattern;
      return info.absoluteFilePath() == match
             || info.fileName() == match;
    };
    return checker;
  }

  static Checker make_regex_checker(const QString& pattern) {
    const QRegularExpression regex(pattern);
    Checker checker = [=](const QFileInfo& info) {
      const auto rx = regex;
      const QString path = info.absoluteFilePath();
      return rx.match(path).hasMatch();
    };
    return checker;
  }

  static Checker make_filenamelist_checker(const QString& pattern) {
    static const QRegularExpression LIST_SPLITER { "[,;]" };
    const QStringList patterns =
      pattern.split(LIST_SPLITER, Qt::SkipEmptyParts);
    QSet<QString> names;
    for (const auto& p : patterns)
      names << QFileInfo(p).fileName();

    Checker checker = [=](const QFileInfo& info) {
      const auto name = info.fileName();
      return names.contains(name);
    };

    return checker;
  }

  static Checker make_suffixlist_checker(const QString& pattern) {
    static const QRegularExpression pat_dot("^\\.+");
    static const auto format_suffix = [=](QString x) {
      x = x.simplified();
      x.remove(pat_dot);
      return x;
    };

    static const QRegularExpression LIST_SPLITER { "[,; ]" };
    const QStringList patterns = pattern.split(LIST_SPLITER);

    QStringList suffixes;
    std::transform(patterns.cbegin(), patterns.cend(),
      std::back_inserter(suffixes), format_suffix);

    QString r = "(";
    r += suffixes.join('|');
    r += ")$";

    const QRegularExpression regex(
      r, QRegularExpression::CaseInsensitiveOption);

    Checker checker = [=](const QFileInfo& info) {
      const auto rx = regex;
      const QString path = info.absoluteFilePath();
      return rx.match(path).hasMatch();
    };

    return checker;
  }

}; // impl

UrlChecker::UrlChecker(QObject* parent)
  : QObject { parent } {
  m_patternBehavior.setValue(PatternIsSuffixList);
  m_acceptFiles.setValue(true);
  m_acceptDirs.setValue(true);

  static const Checker accept_all = [](const QFileInfo&) {
    return true;
  };

  m_pathChecker.setBinding([&] {
    const auto mode = m_patternBehavior.value();
    const auto pattern = m_pattern.value();
    if (pattern.isEmpty())
      return accept_all;

    switch (mode) {
    case PatternIsRegex:
      return Impl::make_regex_checker(pattern);
    case PatternIsFileNameList:
      return Impl::make_filenamelist_checker(pattern);
    case PatternIsSuffixList:
      return Impl::make_suffixlist_checker(pattern);
    default:
      break;
    }
    return Impl::make_fullmatch_checker(pattern);
  });
}

bool UrlChecker::checkType(const QFileInfo& info) const {
  if (info.isDir() && ! acceptDirs())
    return false;
  if (info.isFile() && ! acceptFiles())
    return false;
  return true;
}

bool UrlChecker::isAcceptable(const QUrl& url) const {
  auto check = m_pathChecker.value();
  const QFileInfo info(url.toString(QUrl::PreferLocalFile));
  return checkType(info) && check(info);
}

bool UrlChecker::containsAcceptableUrls(const QList<QUrl>& urls) const {
  if (urls.isEmpty())
    return false;
  static const auto check = [&](const QUrl& url) {
    return this->isAcceptable(url);
  };
  auto found = std::find_if(urls.cbegin(), urls.cend(), check);
  return found != urls.cend();
}

QList<QUrl> UrlChecker::acceptableUrls(const QList<QUrl>& urls) const {
  if (urls.isEmpty())
    return {};
  static const auto check = [&](const QUrl& url) {
    return this->isAcceptable(url);
  };
  QList<QUrl> result;
  std::copy_if(
    urls.cbegin(), urls.cend(), std::back_inserter(result), check);
  return result;
}

QOOL_NS_END
