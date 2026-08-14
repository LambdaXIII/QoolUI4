#ifndef QOOL_SHAPECONTROL_H
#define QOOL_SHAPECONTROL_H

#include "qool_smartobj.h"

#include "qoolcommon/qbindable_property_macros.hpp"
#include <QObject>

#include "qoolns.hpp"
#include <QBindable>
#include <QQmlEngine>
#include <QQuickItem>

QOOL_NS_BEGIN

class ShapeControl : public SmartObject {
  Q_OBJECT
  QML_ELEMENT
public:
  ShapeControl(QObject* parent = nullptr);
  virtual ~ShapeControl() = default;
  Q_INVOKABLE virtual void dumpInfo() const;
  Q_INVOKABLE virtual bool contains(const QPointF& point) const;

protected:
  void appendChild(QObject* child) override;
  void componentComplete() override;

private:
  void setup_properties();
  void connect_target_geometry();

  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, QQuickItem*, target, FINAL)
  // xy仅为target属性的绑定，不代表target内部状态！
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, x, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, y, FINAL)

  // width/height 经信号同步的 target 尺寸缓存（非绑定——隐式尺寸拓扑下
  // target 尺寸经宿主 padding/*Space 链回读自身形成绑定重入环，见
  // connect_target_geometry 注释）；绑定重入检测不适用于
  // 信号→赋值→重算→信号 的收敛迭代。
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, width, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, height, FINAL)
  QProperty<qreal> m_targetWidth { 0.0 };
  QProperty<qreal> m_targetHeight { 0.0 };
  QQuickItem* m_connectedTarget = nullptr;

  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, longEdge, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, shortEdge, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, aspectRatio, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, QPointF, center, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, halfWidth, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, halfHeight, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, QRectF, boundingRect, FINAL)
};

QOOL_NS_END

#endif // QOOL_SHAPECONTROL_H
