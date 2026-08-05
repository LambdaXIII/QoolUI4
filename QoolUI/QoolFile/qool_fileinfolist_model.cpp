#include "qool_fileinfolist_model.h"

#include "qoolcommon/debug.hpp"

// #include "qoolcommon/math/range_counter.hpp"
#include "qoolcommon/qt_tools.hpp"

QOOL_NS_BEGIN

/*!
    \qmltype FileInfoListModel
    \inqmlmodule Qool.File
    \nativetype qoolui::FileInfoListModel
    \brief 以 FileInfo 为数据项的 QAbstractListModel，文件列表视图的数据源。

    内部持有 FileInfoList（默认内部列表，亦可经 \c fileInfos 属性整体
    替换为外部列表）。公开角色：\c fileInfo（FileInfo 对象）、
    \c absoluteFilePath、\c url、\c isFile、\c isDir、\c displayName、
    \c fileName、\c baseName、\c suffix、\c exists、\c size、
    \c birthTime、\c lastModified、\c icon。

    \section1 单线程契约
    本模型所有 API 仅在所属线程（默认主线程）调用。曾用 QRecursiveMutex
    包裹全部操作，但无任何跨线程调用方——锁是死代码，且违背 Qt 模型线程
    规范（QAbstractItemModel 非线程安全，官方约定跨线程访问一律经
    Queued 信号/连接转发，由接收线程独占访问）。若需引入跨线程调用，
    应转发至模型线程而非重新加锁。

    \section1 索引与越界防御
    \c data() 等高频查询入口对非法行号一律返回空值而不越界（部分视图
    实现会把非法 row 传入 data()，at(row) 越界属 UB）；removeAt、
    takeAt 对越界索引发出警告并忽略，removeRange 用断言约束区间。
    批量操作先经 validateIndexes 过滤非法/重复索引、排序去重，再以
    QPersistentModelIndex 固化位置，保证多次移除期间索引漂移不误删元素。

    \section1 move 语义
    \c move(from, to) 遵循 beginMoveRows 的 destinationChild
    "目标行之前的插入点"语义：向下移动时最终落点为 to - 1，故内部
    传 to + 1（Qt 源码 QList::move 落点已含此差一），向上移动传 to。
    \c move(rows, to) 批量移动先把选中行全部移除（持久化索引），再在
    目标行处整体插回；\c to 等于列表长度表示移到末尾（此时 index(to)
    无效，目标行取移除后的列表长度追加）。

    \section1 批量操作契约
    insert/append 的批量重载对空列表直接返回，避免 beginInsertRows
    （first > last）的非法调用；移除类操作在 endRemoveRows 之后统一
    发出 fileInfosRemoved；排序去重类操作（sortInfos、clear、
    forceResetInfos）经 beginResetModel/endResetModel 整体重置，
    fileInfosRemoved 必须延迟到 endResetModel 之后发出——reset 期间
    视图处于中间状态，此时带旧数据 emit 违反模型/视图信号契约。
*/
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
  // 越界防御：data() 是视图高频查询入口，非法 row 在部分实现下
  // 也会到达此处（不依赖 Qt 内部保证），at(row) 越界属 UB
  if (row < 0 || row >= fileInfos()->length())
    return {};
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
  const auto total = fileInfos()->length();
  const int position = qBound(0, index, total);
  const int len = infos.length();

  QList<qsizetype> indexes;

  beginInsertRows({}, position, position + len - 1);
  for (int i = 0; i < len; i++) {
    // 索引必须随 i 递增：position+1 固定值会让后续元素全部插在
    // 同一位置（逆序），且与 beginInsertRows 声明的区间不符。
    const qsizetype index = position + i;
    const qsizetype safe_index = qBound(0, index, fileInfos()->size());
    fileInfos()->insert(safe_index, infos.at(i));
    indexes << index;
  }
  endInsertRows();
  emit fileInfosInserted(indexes);
}

void FileInfoListModel::append(const FileInfo& info) {
  const qsizetype pos = fileInfos()->length();
  beginInsertRows({}, pos, pos);
  fileInfos()->append(info);
  endInsertRows();
  emit fileInfosInserted({ pos });
}

void FileInfoListModel::append(const FileInfoList& infos) {
  // 空列表直接返回：pos + length - 1 会得到 pos-1，
  // beginInsertRows(first > last) 属非法调用（QAbstractItemModel 契约）
  if (infos.isEmpty())
    return;
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

  QList<FileInfo> removedInfos;
  // 先收集再移除：移除后列表已缩短，此时 takeAt(first) 会取到
  // 错误元素并最终越界（UB）
  for (int i = 0; i < last - first + 1; i++)
    removedInfos << fileInfos()->at(first + i);
  beginRemoveRows({}, first, last);
  fileInfos()->remove(first, last - first + 1);
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
  // 显式越界检查：qBound(0, index, total) 在 index==total 时放行
  // total → takeAt(total) 越界（UB），与 removeAt 的检查语义一致
  if (index < 0 || index >= total) {
    xWarningQ << "Index" xDBGRed << index
              << xDBGReset "is not a valid index, operation ignored.";
    return {};
  }
  beginRemoveRows({}, index, index);
  auto result = fileInfos()->takeAt(index);
  endRemoveRows();
  emit fileInfosRemoved({ result });
  return result;
}

FileInfoList FileInfoListModel::take(QList<qsizetype> indexes) {
  if (fileInfos()->isEmpty() || indexes.isEmpty())
    return {};
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
  to = qBound(0, to, total);
  if (from == to)
    return to;
  // 同父向下移动的 destinationChild 语义：Qt 文档（beginMoveRows）
  // 原文——"when moving rows down in the same parent, the rows will be
  // placed before the destinationChild index"，且新索引公式为
  // (destinationChild - sourceLast - 1 + i)（Qt 6.11.1 源码
  // qabstractitemmodel.cpp 3043 行）。QList::move 把元素落到最终位置
  // to，单行代入（sourceLast = from）：to = dest - 1 ⇒ 向下须传
  // to + 1；向上移动无此调整（dest = to）。文档表格 "move row 2 to
  // row 4, destinationChild is 4" 按公式最终位置实为 3——该表措辞
  // 易误读，以公式为准。
  const qsizetype destination = (from < to) ? to + 1 : to;
  beginMoveRows({}, from, from, {}, destination);
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
  to = qBound(0, to, total);
  // 目标与来源统一走 validateIndexes：乱序/重复 rows 会令取出顺序
  // 不确定（插入后顺序漂移），且重复行触发重复移除
  auto valid_rows = validateIndexes(rows);
  if (valid_rows.isEmpty())
    return {};
  auto persistedRows = persistIndexes(valid_rows);
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

  // to == total 时 index(to) 无效（QPersistentModelIndex 无 row）；
  // 该情形语义为"移到列表末尾"——目标行取移除后的列表长度（追加到末尾），
  // 否则 row() = -1 会触发非法 beginInsertRows。
  const auto target_row = persisted_target_row.isValid()
    ? persisted_target_row.row()
    : fileInfos()->length();
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
  // 上限必须是 length()-1：qBound 到 length 会放行 at(length)（越界 UB）
  index = qBound(0, index, fileInfos()->length() - 1);
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

  FileInfoList dirs, files;

  for (const auto& info : std::as_const(*fileInfos()))
    if (info.isDir())
      dirs << info;
    else
      files << info;

  static const auto comp = [](const FileInfo& a, const FileInfo& b) {
    return a.absoluteFilePath() < b.absoluteFilePath();
  };

  std::stable_sort(dirs.begin(), dirs.end(), comp);
  std::stable_sort(files.begin(), files.end(), comp);

  beginResetModel();

  fileInfos()->clear();
  fileInfos()->append(dirs);
  fileInfos()->append(files);

  QSet<FileInfo> dups;
  if (removeDups) {
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
    }
  }

  endResetModel();
  // fileInfosRemoved 必须在 endResetModel 之后发出：reset 期间视图
  // 处于中间状态，此时带旧数据 emit 违反模型/视图信号契约
  if (! dups.isEmpty())
    emit fileInfosRemoved({ dups.constBegin(), dups.constEnd() });
}

void FileInfoListModel::removeDirs() {
  if (fileInfos()->isEmpty())
    return;
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
  beginResetModel();
  m_extInfos = infos;
  endResetModel();
  emit fileInfosChanged();
}

QOOL_NS_END
