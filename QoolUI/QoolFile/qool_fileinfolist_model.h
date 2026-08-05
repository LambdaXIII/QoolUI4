#ifndef QOOL_FILEINFOLIST_MODEL_H
#define QOOL_FILEINFOLIST_MODEL_H

#include "qool_fileinfo.h"

#include "qoolns.hpp"

#include "qoolcommon/qobject_property_macros.hpp"
#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

/**
 * 单线程契约：本模型所有 API 仅在所属线程（默认主线程）调用。
 * 曾用 QRecursiveMutex 包裹全部操作，但无任何跨线程调用方——
 * 锁是死代码，且违背 Qt 模型线程规范（QAbstractItemModel 非线程安全，
 * 官方约定：跨线程访问一律经 Queued 信号/连接转发，由接收线程独占访问）。
 * 移除锁后若引入跨线程调用，须改为转发至模型线程，而非重新加锁。
 */
class FileInfoListModel: public QAbstractListModel {
  Q_OBJECT
  QML_ELEMENT
public:
  enum Role {
    FileInfoRole = Qt::UserRole + 1,
    AbsoluteFilePathRole,
    UrlRole,
    IsFileRole,
    IsDirRole,
    DisplayNameRole,
    FileNameRole,
    BaseNameRole,
    SuffixRole,
    ExistsRole,
    SizeRole,
    BirthTimeRole,
    LastModifiedRole,
    IconRole
  };
  Q_ENUM(Role)

  explicit FileInfoListModel(QObject* parent = nullptr);

  Q_SIGNAL void fileInfosInserted(QList<qsizetype>);
  Q_SIGNAL void fileInfosRemoved(FileInfoList);

  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex& parent = {}) const override;
  QVariant data(const QModelIndex& index,
    int role = Qt::DisplayRole) const override;

  // basic functions

  Q_INVOKABLE qsizetype indexOf(const FileInfo& info) const;

  Q_INVOKABLE void insert(qsizetype index, const FileInfo& info);
  Q_INVOKABLE void insert(qsizetype index, const FileInfoList& infos);

  Q_INVOKABLE void append(const FileInfo& info);
  Q_INVOKABLE void append(const FileInfoList& infos);

  Q_INVOKABLE void removeAt(qsizetype index);
  Q_INVOKABLE void removeRange(qsizetype first, qsizetype last);
  Q_INVOKABLE void remove(QList<qsizetype> indexes);
  // Q_INVOKABLE void remove(const FileInfo& info);

  Q_INVOKABLE FileInfo takeAt(qsizetype index);
  Q_INVOKABLE FileInfoList take(QList<qsizetype> indexes);

  Q_INVOKABLE qsizetype move(qsizetype from, qsizetype to);
  Q_INVOKABLE QList<qsizetype> move(
    const QList<qsizetype>& rows, qsizetype to);
  // Q_INVOKABLE QList<qsizetype> move(const FileInfo& info, qsizetype
  // to);

  Q_INVOKABLE FileInfo infoAt(qsizetype index) const;
  Q_INVOKABLE FileInfoList infos(QList<qsizetype> indexes = {});
  Q_INVOKABLE QList<QUrl> urls(QList<qsizetype> indexes = {});

  Q_INVOKABLE void sortInfos(bool removeDups = true);
  Q_INVOKABLE void removeDirs();
  Q_INVOKABLE void removeFiles();
  Q_INVOKABLE void removeDuplicates();

  Q_INVOKABLE bool isEmpty() const;
  Q_INVOKABLE void clear();
  Q_INVOKABLE void forceResetInfos(const FileInfoList& infos);

protected:
  FileInfoList *m_intInfos, *m_extInfos;

  QList<QPersistentModelIndex> persistIndexes(
    const QList<qsizetype>& indexes) const;
  QList<qsizetype> validateIndexes(QList<qsizetype> indexes) const;

  QOBJECT_WRITABLE_PROPERTY_DECLARE(FileInfoList*, fileInfos)
};

QOOL_NS_END

#endif // QOOL_FILEINFOLIST_MODEL_H
