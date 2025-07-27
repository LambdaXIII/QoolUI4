#include "qool_fileinfolist_model.h"

#include "qoolcommon/debug.hpp"

// #include "qoolcommon/math/range_counter.hpp"
#include "qoolcommon/qt_tools.hpp"

QOOL_NS_BEGIN

#define LOCK_DATA QMutexLocker locker(&m_mutex);

FileInfoListModel::FileInfoListModel(QObject* parent)
  : QAbstractListModel { parent }
  , m_intInfos { new FileInfoList }
  , m_extInfos { nullptr } {
}

QHash<int, QByteArray> FileInfoListModel::roleNames() const {
  static QHash<int, QByteArray> names;
  if (names.isEmpty()) {
    names.insert(QAbstractListModel::roleNames());
    names[FileInfoRole] = "fileInfo";
    names[AbsoluteFilePathRole] = "absoluteFilePath";
    names[UrlRole] = "url";
    names[IsFileRole] = "isFile";
    names[IsDirRole] = "isDir";
    names[DisplayNameRole] = "displayName";
    names[FileNameRole] = "fileName";
    names[BaseNameRole] = "baseName";
    names[SuffixRole] = "suffix";
    names[ExistsRole] = "exists";
    names[SizeRole] = "size";
    names[BirthTimeRole] = "birthTime";
    names[LastModifiedRole] = "lastModified";
    names[IconRole] = "icon";
  }
  return names;
}

int FileInfoListModel::rowCount(const QModelIndex& parent) const {
  if (parent.isValid())
    return 0;
  return fileInfos()->length();
}

QVariant FileInfoListModel::data(
  const QModelIndex& index, int role) const {
  if (! index.isValid())
    return {};

  const int row = index.row();
  const FileInfo& info = fileInfos()->at(row);

  switch (role) {
  case FileInfoRole:
    return QVariant::fromValue(info);
  case AbsoluteFilePathRole:
    return info.absoluteFilePath();
  case UrlRole:
    return info.url();
  case IsFileRole:
    return info.isFile();
  case IsDirRole:
    return info.isDir();
  case Qt::DisplayRole:
  case DisplayNameRole:
  case FileNameRole:
    return info.fileName();
  case BaseNameRole:
    return info.baseName();
  case SuffixRole:
    return info.suffix();
  case ExistsRole:
    return info.exists();
  case SizeRole:
    return info.size();
  case BirthTimeRole:
    return info.birthTime();
  case LastModifiedRole:
    return info.lastModified();
  case IconRole:
    return info.iconUrl();
  }

  return {};
}

qsizetype FileInfoListModel::indexOf(const FileInfo& info) const {
  return fileInfos()->indexOf(info);
}

void FileInfoListModel::insert(qsizetype index, const FileInfo& info) {
  LOCK_DATA
  const auto len = fileInfos()->length();
  index = qBound(0, index, len);

  beginInsertRows({}, index, index);
  fileInfos()->insert(index, info);
  endInsertRows();
  emit fileInfosInserted({ index });
}

void FileInfoListModel::insert(
  qsizetype index, const FileInfoList& infos) {
  if (infos.isEmpty())
    return;
  LOCK_DATA
  const auto total = fileInfos()->length();
  const int position = qBound(0, index, total);
  const int len = infos.length();

  QList<qsizetype> indexes;

  beginInsertRows({}, position, position + len - 1);
  for (int i = 0; i < len; i++) {
    const qsizetype index = position + 1;
    const qsizetype safe_index = qBound(0, index, fileInfos()->size());
    fileInfos()->insert(safe_index, infos.at(i));
    indexes << index;
  }
  endInsertRows();
  emit fileInfosInserted(indexes);
}

void FileInfoListModel::append(const FileInfo& info) {
  LOCK_DATA
  const qsizetype pos = fileInfos()->length();
  beginInsertRows({}, pos, pos);
  fileInfos()->append(info);
  endInsertRows();
  emit fileInfosInserted({ pos });
}

void FileInfoListModel::append(const FileInfoList& infos) {
  const auto pos = fileInfos()->length();
  beginInsertRows({}, pos, pos + infos.length() - 1);
  fileInfos()->append(infos);
  endInsertRows();

  QList<qsizetype> indexes;
  for (int i = 0; i < infos.length(); i++)
    indexes << pos + i;
  emit fileInfosInserted(indexes);
}

void FileInfoListModel::removeAt(qsizetype index) {
  const auto total = fileInfos()->length();
  if (total <= 0)
    return;
  if (index < 0 || index >= total) {
    xWarningQ << "Index" xDBGRed << index
              << xDBGReset "is not a valid index, operation ignored.";
    return;
  }

  LOCK_DATA
  beginRemoveRows({}, index, index);
  auto removed = fileInfos()->takeAt(index);
  endRemoveRows();
  emit fileInfosRemoved({ removed });
}

// QList<qsizetype> __make_index_range(qsizetype first, qsizetype last)
// {
//   QList<qsizetype> result;
//   for (int i = first; i <= last; i++)
//     result << i;
//   return result;
// }

void FileInfoListModel::removeRange(qsizetype first, qsizetype last) {
  const auto total = fileInfos()->length();
  if (total <= 0)
    return;
  Q_ASSERT(first >= 0 && first < total);
  Q_ASSERT(last >= first && last < total);

  LOCK_DATA
  QList<FileInfo> removedInfos;
  beginRemoveRows({}, first, last);
  fileInfos()->remove(first, last - first + 1);

  for (int i = 0; i < last - first + 1; i++)
    removedInfos << fileInfos()->takeAt(first);

  endRemoveRows();
  emit fileInfosRemoved(removedInfos);
}

void FileInfoListModel::remove(QList<qsizetype> indexes) {
  take(indexes);
}

// void FileInfoListModel::remove(const FileInfo& info) {
//   if (fileInfos()->isEmpty())
//     return;
//   LOCK_DATA
//   auto indexes = tools::find_all_indexes(info, *fileInfos());
//   remove(indexes);
// }

FileInfo FileInfoListModel::takeAt(qsizetype index) {
  const auto total = fileInfos()->length();
  if (total <= 0)
    return {};
  LOCK_DATA
  const auto position = qBound(0, index, total);
  beginRemoveRows({}, position, position);
  auto result = fileInfos()->takeAt(position);
  endRemoveRows();
  emit fileInfosRemoved({ result });
  return result;
}

FileInfoList FileInfoListModel::take(QList<qsizetype> indexes) {
  if (fileInfos()->isEmpty() || indexes.isEmpty())
    return {};
  LOCK_DATA
  indexes = validateIndexes(indexes);
  auto p_indexes = persistIndexes(indexes);
  FileInfoList result;
  while (! p_indexes.isEmpty()) {
    const auto current_persisted_index = p_indexes.takeFirst();
    if (! current_persisted_index.isValid())
      continue;
    const auto row = current_persisted_index.row();
    beginRemoveRows({}, row, row);
    result << fileInfos()->takeAt(row);
    endRemoveRows();
  }
  emit fileInfosRemoved(result);
  return result;
}

qsizetype FileInfoListModel::move(qsizetype from, qsizetype to) {
  const auto total = fileInfos()->length();
  if (total <= 0)
    return -1;
  if (from < 0 || from >= total)
    return -1;
  LOCK_DATA
  to = qBound(0, to, total);
  if (from == to)
    return to;
  beginMoveRows({}, from, from, {}, to);
  fileInfos()->move(from, to);
  endMoveRows();
  return to;
}

QList<qsizetype> FileInfoListModel::move(
  const QList<qsizetype>& rows, qsizetype to) {
  const auto total = fileInfos()->length();
  if (total <= 0)
    return {};
  if (rows.isEmpty())
    return {};
  LOCK_DATA
  to = qBound(0, to, total);
  auto persistedRows = persistIndexes(rows);
  auto persisted_target_row = QPersistentModelIndex(index(to));
  FileInfoList took_infos;
  while (! persistedRows.isEmpty()) {
    const auto current_pIndex = persistedRows.takeFirst();
    if (! current_pIndex.isValid())
      continue;
    const auto row = current_pIndex.row();
    beginRemoveRows({}, row, row);
    took_infos << fileInfos()->takeAt(row);
    endRemoveRows();
  }

  if (took_infos.isEmpty()) {
    xWarningQ << "Unknown error occured while moving fileinfos. Data "
                 "might be lost.";
    return {};
  }

  const auto target_row = persisted_target_row.row();
  QList<qsizetype> new_indexes;
  beginInsertRows({}, target_row, target_row + took_infos.length() - 1);
  for (int i = 0; i < took_infos.length(); i++) {
    const qsizetype t = target_row + i;
    const qsizetype safe_t = qBound(0, t, fileInfos()->size());
    fileInfos()->insert(safe_t, took_infos.at(i));
    new_indexes << t;
  }
  endInsertRows();
  return new_indexes;
}

// QList<qsizetype> FileInfoListModel::move(
//   const FileInfo& info, qsizetype to) {
//   const auto total = fileInfos()->length();
//   if (total <= 0)
//     return {};
//   LOCK_DATA;
//   auto indexes = tools::find_all_indexes(info, *fileInfos());
//   return move(indexes, to);
// }

FileInfo FileInfoListModel::infoAt(qsizetype index) const {
  if (fileInfos()->isEmpty())
    return {};
  index = qBound(0, index, fileInfos()->length());
  return fileInfos()->at(index);
}

FileInfoList FileInfoListModel::infos(QList<qsizetype> indexes) {
  const auto total = fileInfos()->length();
  if (total <= 0)
    return {};

  indexes = validateIndexes(indexes);

  FileInfoList result;
  std::transform(indexes.constBegin(), indexes.constEnd(),
    std::back_inserter(result),
    [&](qsizetype i) { return fileInfos()->at(i); });
  return result;
}

QList<QUrl> FileInfoListModel::urls(QList<qsizetype> indexes) {
  const auto total = fileInfos()->length();
  if (total <= 0)
    return {};

  indexes = validateIndexes(indexes);

  QList<QUrl> result;
  std::transform(indexes.constBegin(), indexes.constEnd(),
    std::back_inserter(result),
    [&](qsizetype i) { return fileInfos()->at(i).url(); });
  return result;
}

void FileInfoListModel::sortInfos(bool removeDups) {
  if (fileInfos()->isEmpty())
    return;
  LOCK_DATA

  beginResetModel();
  std::stable_sort(fileInfos()->begin(), fileInfos()->end(),
    [](const FileInfo& a, const FileInfo& b) {
      return a.absoluteFilePath() < b.absoluteFilePath();
    });

  if (removeDups) {
    QSet<FileInfo> dups;
    FileInfo last_info;
    for (const auto& info : std::as_const(*fileInfos())) {
      if (info == last_info)
        dups << info;
      last_info = info;
    }
    if (! dups.isEmpty()) {
      auto last_iter =
        std::unique(fileInfos()->begin(), fileInfos()->end());
      fileInfos()->erase(last_iter, fileInfos()->end());
      fileInfos()->shrink_to_fit();
      emit fileInfosRemoved({ dups.constBegin(), dups.constEnd() });
    }
  }

  endResetModel();
}

void FileInfoListModel::removeDirs() {
  if (fileInfos()->isEmpty())
    return;
  LOCK_DATA
  static const auto pred = [](const FileInfo& info) {
    return info.isDir();
  };

  auto indexes =
    tools::find_all_indexes_if<FileInfo>(pred, *fileInfos());
  remove(indexes);
}

void FileInfoListModel::removeFiles() {
  if (fileInfos()->isEmpty())
    return;
  LOCK_DATA
  static const auto pred = [](const FileInfo& info) {
    return info.isFile();
  };

  auto indexes =
    tools::find_all_indexes_if<FileInfo>(pred, *fileInfos());
  remove(indexes);
}

void FileInfoListModel::removeDuplicates() {
  if (fileInfos()->isEmpty())
    return;
  LOCK_DATA
  QList<qsizetype> dupIndexes;
  QSet<FileInfo> existed;
  for (int i = 0; i < fileInfos()->length(); i++) {
    const auto& info = fileInfos()->at(i);
    if (existed.contains(info))
      dupIndexes << i;
    else
      existed << info;
  }
  remove(dupIndexes);
}

bool FileInfoListModel::isEmpty() const {
  return fileInfos()->isEmpty();
}

void FileInfoListModel::clear() {
  if (fileInfos()->isEmpty())
    return;
  LOCK_DATA
  QSet<FileInfo> infos { fileInfos()->constBegin(),
    fileInfos()->constEnd() };
  beginResetModel();
  fileInfos()->clear();
  endResetModel();
  emit fileInfosRemoved({ infos.constBegin(), infos.constEnd() });
}

void FileInfoListModel::forceResetInfos(const FileInfoList& infos) {
  QSet<FileInfo> old_infos { fileInfos()->constBegin(),
    fileInfos()->constEnd() };
  QSet<FileInfo> new_infos { infos.constBegin(), infos.constEnd() };
  if (old_infos == new_infos)
    return;
  LOCK_DATA
  beginResetModel();
  *fileInfos() = infos;
  endResetModel();

  auto removed_infos = old_infos.subtract(new_infos);
  emit fileInfosRemoved(
    { removed_infos.constBegin(), removed_infos.constEnd() });
}

QList<QPersistentModelIndex> FileInfoListModel::persistIndexes(
  const QList<qsizetype>& indexes) const {
  QList<QPersistentModelIndex> pIndexes;
  std::transform(indexes.constBegin(), indexes.constEnd(),
    std::back_inserter(pIndexes),
    [&](qsizetype i) { return QPersistentModelIndex(index(i)); });
  pIndexes.removeIf(
    [](const QPersistentModelIndex& p) { return ! p.isValid(); });
  return pIndexes;
}

QList<qsizetype> FileInfoListModel::validateIndexes(
  QList<qsizetype> indexes) const {
  const auto total = fileInfos()->length();
  if (indexes.isEmpty() || total <= 0)
    return indexes;
  indexes.removeIf([&](qsizetype i) { return i < 0 || i >= total; });
  std::stable_sort(indexes.begin(), indexes.end());
  auto last = std::unique(indexes.begin(), indexes.end());
  indexes.erase(last, indexes.end());
  indexes.shrink_to_fit();
  return indexes;
}

FileInfoList* FileInfoListModel::fileInfos() const {
  return m_extInfos ? m_extInfos : m_intInfos;
}

void FileInfoListModel::set_fileInfos(FileInfoList* infos) {
  if (fileInfos() == infos)
    return;
  LOCK_DATA
  beginResetModel();
  m_extInfos = infos;
  endResetModel();
  emit fileInfosChanged();
}

#undef LOCK_DATA
QOOL_NS_END
