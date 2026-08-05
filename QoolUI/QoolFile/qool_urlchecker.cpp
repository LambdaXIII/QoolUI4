#include "qool_urlchecker.h"

#include <QCache>
#include <QFileInfo>

QOOL_NS_BEGIN

/*!
    \qmltype UrlChecker
    \inqmlmodule Qool.File
    \nativetype qoolui::UrlChecker
    \brief 按路径规则与文件类型过滤 URL 的校验器（拖放接受策略）。

    \c pattern 的匹配方式由 \c patternBehavior 决定，共四种模式：
    \list
    \li \c FullMatch：绝对路径或文件名与 pattern 完全相等；
    \li \c PatternIsRegex：以 QRegularExpression 对整个绝对路径做正则匹配；
    \li \c PatternIsFileNameList：以逗号/分号分隔的文件名列表，路径的文件名
        命中集合即接受；
    \li \c PatternIsSuffixList（默认）：以逗号/分号/空格分隔的后缀列表，
        后缀去除前导点并转义后拼为 "(suffix1|suffix2…)$" 不区分大小写
        匹配路径末尾——空段被 SkipEmptyParts 丢弃，避免空后缀产生恒真的
        空分支；后缀必须转义，否则含正则元字符（如 "c++"）会改变匹配结构。
    \endlist
    \c pattern 为空时接受一切路径。

    \c acceptDirs/acceptFiles 控制是否接受目录/文件，默认均接受；
    \c checkType() 先按类型过滤（目录不受 acceptFiles 约束，反之亦然），
    再由 \c isAcceptable() 把类型判定与路径规则检查合并为最终结论。
    检查器经 QProperty 绑定随 \c pattern/\c patternBehavior 变化即时
    重建，规则改动无需重建对象。

    \note containsAcceptableUrls/acceptableUrls 内捕获 this 的 lambda
    不可声明为 static：局部 static 仅初始化一次，捕获的是首次调用实例
    的指针——首例析构后悬垂，且跨实例串用检查逻辑。
*/
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
    // SkipEmptyParts：空段会产生空后缀 ""，正则变成 "(|png|jpg)$"，
    // 任何路径都匹配（空分支恒真）
    const QStringList patterns = pattern.split(
      LIST_SPLITER, Qt::SkipEmptyParts);

    QStringList suffixes;
    std::transform(patterns.cbegin(), patterns.cend(),
      std::back_inserter(suffixes), format_suffix);

    // 后缀须转义后拼入正则：后缀含正则元字符（"."、"+"、"(" 等）
    // 会改变匹配结构（如 "c++" 后缀成为量词表达式）
    QStringList escaped;
    std::transform(suffixes.cbegin(), suffixes.cend(),
      std::back_inserter(escaped),
      [](const QString& s) { return QRegularExpression::escape(s); });

    QString r = "(";
    r += escaped.join('|');
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
  // 不可用 static：局部 static 仅初始化一次，捕获的 this 是首次调用
  // 实例的指针——首个实例析构后悬垂，且跨实例串用检查逻辑
  const auto check = [&](const QUrl& url) {
    return this->isAcceptable(url);
  };
  auto found = std::find_if(urls.cbegin(), urls.cend(), check);
  return found != urls.cend();
}

QList<QUrl> UrlChecker::acceptableUrls(const QList<QUrl>& urls) const {
  if (urls.isEmpty())
    return {};
  // 同上：static + 捕获 this 会跨实例串用与悬垂
  const auto check = [&](const QUrl& url) {
    return this->isAcceptable(url);
  };
  QList<QUrl> result;
  std::copy_if(
    urls.cbegin(), urls.cend(), std::back_inserter(result), check);
  return result;
}

QOOL_NS_END
