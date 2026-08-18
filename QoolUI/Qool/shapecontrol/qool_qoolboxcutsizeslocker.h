#ifndef QOOL_QOOLBOXCUTSIZESLOCKER_H
#define QOOL_QOOLBOXCUTSIZESLOCKER_H

#include "qool_qoolbox_settings.h"
#include "qool_smartobj.h"
#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <array>

QOOL_NS_BEGIN

// QoolBoxSettings 专属插件：启用期把四角切角统一为 cutSize，停用时恢复
// 进入本次锁定前一刻的快照。构造时经 parent 自动挂接 target（parent 非
// QoolBoxSettings 时 target 为 null，安全空转）。
//
// 快照时机 = 进入锁定状态（enabled && target 有效）的瞬间：
// enabled 由 false→true 或 enabled 期间更换 target，都重新快照。
class QoolBoxCutSizesLocker : public SmartObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(CutSizesLocker)

public:
  explicit QoolBoxCutSizesLocker(QObject* parent = nullptr);

protected:
  std::array<qreal, 4> m_old_sizes{0, 0, 0, 0};
  QoolBoxSettings* m_target{nullptr};

  Q_SLOT void whenCutSizesChanged();
  Q_SLOT void whenEnabledChanged();

  void setup_target(QoolBoxSettings* settings);
  void teardown_target(QoolBoxSettings* settings);
  void snapshot_target(QoolBoxSettings* settings);
  void restore_target(QoolBoxSettings* settings);
  void unify_target();

  QOBJECT_WRITABLE_PROPERTY(bool, enabled, true)
  QOBJECT_WRITABLE_PROPERTY(qreal, cutSize, 0)
  QOBJECT_WRITABLE_PROPERTY_DECLARE(QoolBoxSettings*, target)
};

QOOL_NS_END

#endif // QOOL_QOOLBOXCUTSIZESLOCKER_H
