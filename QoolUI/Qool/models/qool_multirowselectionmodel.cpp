#include "qool_multirowselectionmodel.h"

QOOL_NS_BEGIN

MultiRowSelectionModel::MultiRowSelectionModel(
  QAbstractListModel* model, QObject* parent)
  : QItemSelectionModel { model, parent } {
  connect(this,
    &QItemSelectionModel::currentChanged,
    [&](QModelIndex, QModelIndex) { emit currentRowUpdated(); });
}

QItemSelection MultiRowSelectionModel::totalSelection() const {
  auto head = model()->index(0, 0);
  auto tail = model()->index(model()->rowCount() - 1, 0);

  QItemSelection selection(head, tail);
  return selection;
}

void MultiRowSelectionModel::selectRow(int row, bool forceSelect) {
  auto index = model()->index(row, 0);
  if (! index.isValid())
    return;

  bool was_selected = isRowSelected(row);

  clear();

  if (forceSelect || (! was_selected))
    select(
      index, QItemSelectionModel::Select | QItemSelectionModel::Rows);

  setCurrentIndex(
    index, QItemSelectionModel::NoUpdate | QItemSelectionModel::Rows);
}

void MultiRowSelectionModel::toggleRow(int row) {
  auto index = model()->index(row, 0);
  if (! index.isValid())
    return;

  bool was_selected = isRowSelected(row);

  clear();

  if (! was_selected)
    select(
      index, QItemSelectionModel::Select | QItemSelectionModel::Rows);
  else
    select(
      index, QItemSelectionModel::Deselect | QItemSelectionModel::Rows);

  setCurrentIndex(
    index, QItemSelectionModel::NoUpdate | QItemSelectionModel::Rows);
}

void MultiRowSelectionModel::selectRows(const QList<int>& rows) {
  if (rows.isEmpty())
    return;
  for (int row : rows)
    multiSelectRow(row);
}

void MultiRowSelectionModel::multiSelectRow(int row, bool forceSelect) {
  auto index = model()->index(row, 0);
  if (! index.isValid())
    return;
  setCurrentIndex(
    index, QItemSelectionModel::NoUpdate | QItemSelectionModel::Rows);

  if (forceSelect)
    select(
      index, QItemSelectionModel::Select | QItemSelectionModel::Rows);
  else
    select(
      index, QItemSelectionModel::Toggle | QItemSelectionModel::Rows);
}

void MultiRowSelectionModel::rangeSelectRow(int row) {
  auto index = model()->index(row, 0);

  if (! currentIndex().isValid())
    return;

  int previous = currentIndex().row();

  if (! isRowSelected(previous)) {
    selectRow(row);
    return;
  }

  int top = qMin(previous, row);
  int bottom = qMax(previous, row);

  QItemSelection selection(
    model()->index(top, 0), model()->index(bottom, 0));
  select(
    selection, QItemSelectionModel::Select | QItemSelectionModel::Rows);
  setCurrentIndex(
    index, QItemSelectionModel::NoUpdate | QItemSelectionModel::Rows);
}

void MultiRowSelectionModel::selectAll(bool selected) {
  auto flag =
    selected ?
      QItemSelectionModel::Select | QItemSelectionModel::Rows :
      QItemSelectionModel::Deselect | QItemSelectionModel::Rows;

  select(totalSelection(), flag);
}

void MultiRowSelectionModel::toggleAll() {
  select(totalSelection(),
    QItemSelectionModel::Rows | QItemSelectionModel::Toggle);
}

QList<int> MultiRowSelectionModel::selectedRows() const {
  QList<QModelIndex> indexes = QItemSelectionModel::selectedRows();
  QSet<int> result;
  for (const auto& i : indexes)
    result << i.row();
  return { result.constBegin(), result.constEnd() };
}

void MultiRowSelectionModel::selectAllIfNoSelection() {
  auto selected = selectedRows();
  if (selected.isEmpty())
    selectAll(true);
}

int MultiRowSelectionModel::currentRow() const {
  auto c = currentIndex();
  if (c.isValid())
    return c.row();
  return -1;
}

QOOL_NS_END
