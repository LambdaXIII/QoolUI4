// Qool 核心 C++ 类型测试：CutSizesLocker（Qool/shapecontrol/）
//
// 被测面（spec「Testing Decisions」双测试接缝的 core 层）：
//   - 默认值（enabled true、cutSize 0、target null 空转安全）
//   - cutSize 设置 → 四角全部同步（TL/TR/BL/BR 均等于 cutSize）
//   - 单角外部改动（enabled 期）→ 其余三角联动统一
//   - enabled=false → 四角恢复锁定前快照；停用期改角不被打断
//   - 恢复 enabled 重新锁定（enabled 由 false→true 时快照时机正确）
//   - enabled 期间更换 target → 新 target 立即统一、旧 target 恢复其快照
//   - target 为 null / 未挂接时启用空转不崩溃
//
// 只测外部行为与公开契约；数值用 fuzzy_eq 容差。

#include <QtTest>

#include "qool_test.hpp"

#include "shapecontrol/qool_qoolbox_settings.h"
#include "shapecontrol/qool_qoolboxcutsizeslocker.h"

#include <cmath>

using namespace qoolui;

namespace {

bool fuzzy_eq(qreal actual, qreal expected, qreal eps = 1e-4) {
  return std::abs(actual - expected) <= eps;
}

bool corners_eq(const QoolBoxSettings& s, qreal tl, qreal tr, qreal bl,
    qreal br, qreal eps = 1e-4) {
  return fuzzy_eq(s.cutSizeTL(), tl, eps) && fuzzy_eq(s.cutSizeTR(), tr, eps)
      && fuzzy_eq(s.cutSizeBL(), bl, eps) && fuzzy_eq(s.cutSizeBR(), br, eps);
}

} // namespace

class TestQoolBoxCutSizesLockerUnit : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(defaults_safe_idle) {
  // 默认值 + target 为 null 时启用/设置 cutSize 均空转不崩溃
  QoolBoxCutSizesLocker locker;
  QVERIFY(locker.enabled());
  QVERIFY(fuzzy_eq(locker.cutSize(), 0));
  QVERIFY(locker.target() == nullptr);

  locker.set_cutSize(12);
  QVERIFY(fuzzy_eq(locker.cutSize(), 12));
  locker.set_enabled(false);
  locker.set_enabled(true);
  locker.set_target(nullptr);
}

  QOOL_TEST_CASE(parent_auto_hook_snapshot_on_enter) {
  // 构造时经 parent 自动挂接 target；进入锁定瞬间快照四角原始值，
  // 随后立即统一为当前 cutSize（默认 0）。停用恢复构造前快照。
  QoolBoxSettings settings;
  settings.set_cutSizeTL(1);
  settings.set_cutSizeTR(2);
  settings.set_cutSizeBL(3);
  settings.set_cutSizeBR(4);

  QoolBoxCutSizesLocker locker(&settings);
  QVERIFY(locker.target() == &settings);
  QVERIFY(corners_eq(settings, 0, 0, 0, 0));

  locker.set_cutSize(8);
  QVERIFY(corners_eq(settings, 8, 8, 8, 8));

  locker.set_enabled(false);
  QVERIFY(corners_eq(settings, 1, 2, 3, 4));
}

  QOOL_TEST_CASE(cutSize_unifies_four_corners) {
  // cutSize 设置 → 四角全部同步；target 变更后按当前 cutSize 统一
  QoolBoxSettings settings;
  settings.set_cutSizeTL(1);
  settings.set_cutSizeTR(2);
  settings.set_cutSizeBL(3);
  settings.set_cutSizeBR(4);

  QoolBoxCutSizesLocker locker;
  locker.set_cutSize(7);
  locker.set_target(&settings);
  QVERIFY(corners_eq(settings, 7, 7, 7, 7));

  locker.set_cutSize(9);
  QVERIFY(corners_eq(settings, 9, 9, 9, 9));
}

  QOOL_TEST_CASE(single_corner_change_unifies_others) {
  // enabled 期外部直接改 target 任一角 → 该角值同步回 locker.cutSize，
  // 其余三角自动联动为同一值
  QoolBoxSettings settings;
  QoolBoxCutSizesLocker locker;
  locker.set_cutSize(7);
  locker.set_target(&settings);
  QVERIFY(corners_eq(settings, 7, 7, 7, 7));

  settings.set_cutSizeTR(25);
  QVERIFY(fuzzy_eq(locker.cutSize(), 25));
  QVERIFY(corners_eq(settings, 25, 25, 25, 25));

  settings.set_cutSizeBL(30);
  QVERIFY(fuzzy_eq(locker.cutSize(), 30));
  QVERIFY(corners_eq(settings, 30, 30, 30, 30));
}

  QOOL_TEST_CASE(disable_restores_snapshot_and_frees_corners) {
  // enabled=false → 四角恢复锁定前快照；停用期改角不被覆盖
  QoolBoxSettings settings;
  settings.set_cutSizeTL(1);
  settings.set_cutSizeTR(2);
  settings.set_cutSizeBL(3);
  settings.set_cutSizeBR(4);

  QoolBoxCutSizesLocker locker;
  locker.set_cutSize(8);
  locker.set_target(&settings);
  QVERIFY(corners_eq(settings, 8, 8, 8, 8));

  locker.set_enabled(false);
  QVERIFY(corners_eq(settings, 1, 2, 3, 4));

  settings.set_cutSizeTL(100);
  QVERIFY(fuzzy_eq(settings.cutSizeTL(), 100));
  QVERIFY(fuzzy_eq(settings.cutSizeTR(), 2));
}

  QOOL_TEST_CASE(reenable_snapshots_current_then_locks_again) {
  // enabled 由 false→true（target 已有效）→ 快照当前四角，
  // 恢复 enabled 再次锁定；再次停用恢复到第二次锁定前的值
  QoolBoxSettings settings;
  settings.set_cutSizeTL(1);
  settings.set_cutSizeTR(2);
  settings.set_cutSizeBL(3);
  settings.set_cutSizeBR(4);

  QoolBoxCutSizesLocker locker;
  locker.set_cutSize(8);
  locker.set_target(&settings);
  locker.set_enabled(false);

  settings.set_cutSizeTL(100);

  locker.set_enabled(true);
  QVERIFY(corners_eq(settings, 8, 8, 8, 8));

  locker.set_enabled(false);
  QVERIFY(corners_eq(settings, 100, 2, 3, 4));
}

  QOOL_TEST_CASE(disabled_cutSize_change_does_not_touch_target) {
  // 停用期改 cutSize 只更新自身，target 四角保持原值
  QoolBoxSettings settings;
  settings.set_cutSizeTL(1);
  settings.set_cutSizeTR(2);
  settings.set_cutSizeBL(3);
  settings.set_cutSizeBR(4);

  QoolBoxCutSizesLocker locker;
  locker.set_enabled(false);
  locker.set_target(&settings);
  locker.set_cutSize(50);
  QVERIFY(fuzzy_eq(locker.cutSize(), 50));
  QVERIFY(corners_eq(settings, 1, 2, 3, 4));
}

  QOOL_TEST_CASE(target_change_while_enabled_restores_old_unifies_new) {
  // enabled 期间更换 target → 旧 target 恢复其快照，
  // 新 target 立即按当前 cutSize 统一；之后停用只恢复新 target
  QoolBoxSettings first;
  first.set_cutSizeTL(1);
  first.set_cutSizeTR(2);
  first.set_cutSizeBL(3);
  first.set_cutSizeBR(4);

  QoolBoxCutSizesLocker locker;
  locker.set_cutSize(8);
  locker.set_target(&first);
  QVERIFY(corners_eq(first, 8, 8, 8, 8));

  QoolBoxSettings second;
  second.set_cutSizeTL(5);
  second.set_cutSizeTR(6);
  second.set_cutSizeBL(7);
  second.set_cutSizeBR(8);

  locker.set_target(&second);
  QVERIFY(locker.target() == &second);
  QVERIFY(corners_eq(first, 1, 2, 3, 4));
  QVERIFY(corners_eq(second, 8, 8, 8, 8));

  locker.set_enabled(false);
  QVERIFY(corners_eq(second, 5, 6, 7, 8));
  QVERIFY(corners_eq(first, 1, 2, 3, 4));
}

  QOOL_TEST_CASE(target_change_to_null_while_enabled_restores_old) {
  // enabled 期间把 target 置 null → 旧 target 恢复快照，locker 空转
  QoolBoxSettings settings;
  settings.set_cutSizeTL(1);
  settings.set_cutSizeTR(2);
  settings.set_cutSizeBL(3);
  settings.set_cutSizeBR(4);

  QoolBoxCutSizesLocker locker;
  locker.set_cutSize(8);
  locker.set_target(&settings);
  QVERIFY(corners_eq(settings, 8, 8, 8, 8));

  locker.set_target(nullptr);
  QVERIFY(locker.target() == nullptr);
  QVERIFY(corners_eq(settings, 1, 2, 3, 4));

  locker.set_enabled(false);
  locker.set_enabled(true);
  QVERIFY(locker.target() == nullptr);
}

  QOOL_TEST_CASE(disabled_target_change_then_enable_snapshots_new) {
  // 快照时机 = 进入锁定状态（enabled && target 有效）的瞬间：
  // enabled 不变而 target 更换同样触发重新快照；enabled=false 时
  // 挂接 target 不立即统一，待 enabled=true 才快照 + 统一
  QoolBoxSettings settings;
  settings.set_cutSizeTL(1);
  settings.set_cutSizeTR(2);
  settings.set_cutSizeBL(3);
  settings.set_cutSizeBR(4);

  QoolBoxCutSizesLocker locker;
  locker.set_enabled(false);
  locker.set_target(&settings);
  QVERIFY(corners_eq(settings, 1, 2, 3, 4));

  settings.set_cutSizeTL(10);
  settings.set_cutSizeTR(20);
  settings.set_cutSizeBL(30);
  settings.set_cutSizeBR(40);

  locker.set_cutSize(8);
  locker.set_enabled(true);
  QVERIFY(corners_eq(settings, 8, 8, 8, 8));

  locker.set_enabled(false);
  QVERIFY(corners_eq(settings, 10, 20, 30, 40));
}
};

QTEST_MAIN(TestQoolBoxCutSizesLockerUnit)
#include "tst_qoolboxcutsizeslocker.moc"
