#ifndef QOOL_MULTIROWSELECTIONMODEL_H
#define QOOL_MULTIROWSELECTIONMODEL_H

#include "qoolns.hpp"

#include <QAbstractListModel>
#include <QItemSelectionModel>
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class MultiRowSelectionModel: public QItemSelectionModel {
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(int currentRow READ currentRow NOTIFY currentRowUpdated)

protected:
  QItemSelection totalSelection() const;

public:
  explicit MultiRowSelectionModel(
    QAbstractListModel* model = nullptr, QObject* parent = nullptr);

  Q_SLOT void selectRow(int row, bool forceSelect = false);
  Q_SLOT void toggleRow(int row);

  Q_SLOT void selectRows(const QList<int>& rows);
  Q_SLOT void multiSelectRow(int row, bool forceSelect = false);

  Q_SLOT void rangeSelectRow(int row);

  Q_SLOT void selectAll(bool selected = true);

  Q_SLOT void toggleAll();

  Q_INVOKABLE QList<int> selectedRows() const;

  Q_SLOT void selectAllIfNoSelection();

  Q_SIGNAL void currentRowUpdated();
  int currentRow() const;
};

QOOL_NS_END

#endif // QOOL_MULTIROWSELECTIONMODEL_H
