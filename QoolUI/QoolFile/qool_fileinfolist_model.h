#ifndef QOOL_FILEINFOLIST_MODEL_H
#define QOOL_FILEINFOLIST_MODEL_H

#include "qool_fileinfo.h"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolns.hpp"

#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>
#include <QRecursiveMutex>

QOOL_NS_BEGIN

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
  QRecursiveMutex m_mutex;

  QList<QPersistentModelIndex> persistIndexes(
    const QList<qsizetype>& indexes) const;
  QList<qsizetype> validateIndexes(QList<qsizetype> indexes) const;

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(FileInfoList*, fileInfos)
};

QOOL_NS_END

#endif // QOOL_FILEINFOLIST_MODEL_H
