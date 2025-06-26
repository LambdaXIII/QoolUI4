#ifndef QOOLCOMMMON_SIMPLE_PATH_EXPANDER_HPP

#define QOOLCOMMMON_SIMPLE_PATH_EXPANDER_HPP

#include "qoolns.hpp"

#include <QDir>
#include <QStringList>
#include <QfileInfo>

QOOL_NS_BEGIN

struct SimplePathExpander {
  QStringList locations;
  QStringList subDirectories;
  QStringList extraLocations; // will not expand with subDirectories

  inline QStringList searchPaths() const {
    QStringList result;
    for (const auto& location : locations) {
      QString base = QFileInfo(location).absoluteFilePath();
      result << base;
      for (const auto& subDir : subDirectories)
        result << base + QDir::separator() + subDir;
    }

    result.append(extraLocations);
    result.removeIf([](const QString& path) {
      const QFileInfo info(path);
      return ! (info.exists() && info.isDir());
    });
    return result;
  }

  inline QFileInfoList entryInfoList(
    const QStringList& nameFilters = {}) const {
    QList<QFileInfo> result;
    const QStringList dir_paths = searchPaths();
    for (const auto& dir_path : dir_paths) {
      QDir dir(dir_path);
      result << dir.entryInfoList(nameFilters, QDir::Files);
    }

    std::stable_sort(result.begin(), result.end(),
      [](const QFileInfo& a, const QFileInfo& b) {
        return a.absoluteFilePath() < b.absoluteFilePath();
      });

    auto last = std::unique(result.begin(), result.end());
    result.erase(last, result.end());
    return result;
  };

  inline QStringList entryList(
    const QStringList& nameFilters = {}) const {
    QFileInfoList infos = entryInfoList(nameFilters);
    QStringList result;
    std::transform(infos.cbegin(), infos.cend(),
      std::back_inserter(result),
      [&](const QFileInfo& info) { return info.absoluteFilePath(); });
    result.shrink_to_fit();
    return result;
  }
};

QOOL_NS_END

#endif // QOOLCOMMMON_SIMPLE_PATH_EXPANDER_HPP