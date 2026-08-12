// Qool 核心 C++ 类型测试：MultiRowSelectionModel（Qool/models/qool_multirowselectionmodel.h）
//
// 被测面：QItemSelectionModel 子类的多行选择状态逻辑——
//   - selectRow：单行选择（先清空）；已选中行再 selectRow 取消（forceSelect 保持）
//   - toggleRow / multiSelectRow：切换选择
//   - selectRows：批量多选（不清空）
//   - rangeSelectRow：从 currentRow 到目标行的范围选择；current 行未选中时回退单行
//   - selectAll / toggleAll / selectAllIfNoSelection
//   - selectedRows / currentRow / currentRowUpdated 信号契约
//
// 注意：selectedRows() 内部经 QSet 去重，返回顺序不保证——断言一律先排序。
// 数据源用 QStringListModel（Qt Core 自带，无 UI 依赖）。

#include <QtTest>
#include <QSignalSpy>

#include "qool_test.hpp"

#include "models/qool_multirowselectionmodel.h"

#include <QStringListModel>
#include <algorithm>

using namespace qoolui;

namespace {

// QStringListModel 不可拷贝（QAbstractItemModel 禁拷贝）——helper 只提供数据
QStringList makeNames() {
  return { "a", "b", "c", "d", "e" }; // 5 行
}

QList<int> sorted(const QList<int>& rows) {
  auto result = rows;
  std::sort(result.begin(), result.end());
  return result;
}

} // namespace

class TestMultiRowSelectionModel : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(initial_state) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);
  QVERIFY(sel.selectedRows().isEmpty());
  QCOMPARE(sel.currentRow(), -1);
}
  QOOL_TEST_CASE(select_row_single_selection) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);

  sel.selectRow(2);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 2 }));
  QCOMPARE(sel.currentRow(), 2);

  // 换行选择：先清空再选（单选语义）
  sel.selectRow(0);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0 }));
  QCOMPARE(sel.currentRow(), 0);
}
  QOOL_TEST_CASE(select_row_already_selected_cancels) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);

  sel.selectRow(2);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 2 }));
  // 已选中行再 selectRow（不 force）→ 取消选择（点击已选中行 = 取消）
  sel.selectRow(2);
  QVERIFY(sel.selectedRows().isEmpty());
  // forceSelect：即使已选中也保持选中
  sel.selectRow(2, true);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 2 }));
}
  QOOL_TEST_CASE(toggle_row) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);

  sel.toggleRow(1);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 1 }));
  sel.toggleRow(1);
  QVERIFY(sel.selectedRows().isEmpty());
  sel.toggleRow(3);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 3 }));
  QCOMPARE(sel.currentRow(), 3);
}
  QOOL_TEST_CASE(multi_select_row_toggle) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);

  sel.multiSelectRow(1);
  sel.multiSelectRow(3);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 1, 3 }));
  // 再次 multiSelectRow 已选中行 → 切换为取消
  sel.multiSelectRow(1);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 3 }));
  // forceSelect：强制选中（不切换）
  sel.multiSelectRow(3, true);
  sel.multiSelectRow(3, true);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 3 }));
}
  QOOL_TEST_CASE(select_rows_batch) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);

  sel.selectRows({ 0, 2, 4 });
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0, 2, 4 }));
  // 追加（不清空）
  sel.selectRows({ 1 });
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0, 1, 2, 4 }));
  // 空列表不动作
  sel.selectRows({});
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0, 1, 2, 4 }));
}
  QOOL_TEST_CASE(range_select) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);

  sel.selectRow(1);
  sel.rangeSelectRow(3);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 1, 2, 3 }));
  QCOMPARE(sel.currentRow(), 3);
  // 继续扩展范围
  sel.rangeSelectRow(4);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 1, 2, 3, 4 }));
  QCOMPARE(sel.currentRow(), 4);
  // 反向范围
  sel.rangeSelectRow(0);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0, 1, 2, 3, 4 }));
  QCOMPARE(sel.currentRow(), 0);
}
  QOOL_TEST_CASE(range_select_falls_back_when_current_unselected) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);

  // 构造 currentRow 未选中的状态：selectRow 后 toggleRow 取消
  sel.selectRow(0);
  sel.toggleRow(0);
  QCOMPARE(sel.currentRow(), 0);
  QVERIFY(sel.selectedRows().isEmpty());

  // current 行未选中 → rangeSelectRow 回退为单行选择（清空 + 只选目标行）
  sel.rangeSelectRow(2);
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 2 }));
  QCOMPARE(sel.currentRow(), 2);
}
  QOOL_TEST_CASE(select_all_and_toggle_all) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);

  sel.selectAll();
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0, 1, 2, 3, 4 }));
  sel.selectAll(false);
  QVERIFY(sel.selectedRows().isEmpty());
  sel.toggleAll();
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0, 1, 2, 3, 4 }));
  sel.toggleAll();
  QVERIFY(sel.selectedRows().isEmpty());
}
  QOOL_TEST_CASE(select_all_if_no_selection) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);

  // 无选择 → 全选
  sel.selectAllIfNoSelection();
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0, 1, 2, 3, 4 }));
  // 有选择 → 不动作
  sel.selectAllIfNoSelection();
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0, 1, 2, 3, 4 }));
  // 局部选择 → 不动作
  sel.selectAll(false);
  sel.selectRows({ 0, 2 });
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0, 2 }));
  sel.selectAllIfNoSelection();
  QCOMPARE(sorted(sel.selectedRows()), QList<int>({ 0, 2 }));
}
  QOOL_TEST_CASE(current_row_updated_signal) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);
  QSignalSpy spy(&sel, &MultiRowSelectionModel::currentRowUpdated);

  // selectRow 改变 current → 发出
  sel.selectRow(2);
  QVERIFY(spy.count() >= 1);
  // selectRow 其他行 → 发出
  sel.selectRow(3);
  QVERIFY(spy.count() >= 2);
  // selectAll 不改变 current → 不发出
  const int before = spy.count();
  sel.selectAll();
  sel.selectAll(false);
  QCOMPARE(spy.count(), before);
  // 再次 selectRow 同一行（选择状态从选中变取消，current 先清空再复位）→ 发出
  sel.selectRow(3);
  QVERIFY(spy.count() > before);
}
  QOOL_TEST_CASE(invalid_rows_noop) {
  QStringListModel model(makeNames());
  MultiRowSelectionModel sel(&model);

  // 越界/负数行：无操作（不崩溃、状态不变）
  sel.selectRow(-1);
  sel.selectRow(99);
  sel.toggleRow(-1);
  sel.toggleRow(99);
  sel.multiSelectRow(-1);
  sel.rangeSelectRow(99);
  QVERIFY(sel.selectedRows().isEmpty());
  QCOMPARE(sel.currentRow(), -1);
}
  QOOL_TEST_CASE(empty_model) {
  QStringListModel model; // 无数据
  MultiRowSelectionModel sel(&model);

  sel.selectRow(0);
  sel.toggleRow(0);
  sel.selectAll();
  sel.toggleAll();
  sel.rangeSelectRow(0);
  sel.selectAllIfNoSelection();
  QVERIFY(sel.selectedRows().isEmpty());
  QCOMPARE(sel.currentRow(), -1);
}
};

QTEST_MAIN(TestMultiRowSelectionModel)

#include "tst_multirowselectionmodel.moc"
