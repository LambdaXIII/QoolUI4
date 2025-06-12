#include "qool_shapehelpergadget.h"

QOOL_NS_BEGIN

ShapeHelperGadget::ShapeHelperGadget(QObject* parent)
  : QObject { parent } {
  m_shapeHelper.setValue(nullptr);
  m_shapeTarget.setBinding([&] {
    ShapeHelper* helper = m_shapeHelper.value();
    return helper ? helper->bindable_target().value() : nullptr;
  });

  m_targetWidth.setBinding([&] {
    auto helper = m_shapeHelper.value();
    if (helper)
      return helper->bindable_width().value();
    auto target = m_shapeTarget.value();
    if (target)
      return target->bindableWidth().value();
    return 0.0;
  });

  m_targetHeight.setBinding([&] {
    auto helper = m_shapeHelper.value();
    if (helper)
      return helper->bindable_height().value();
    auto target = m_shapeTarget.value();
    if (target)
      return target->bindableWidth().value();
    return 0.0;
  });

  m_targetSize.setBinding([&] {
    return QSizeF(m_targetWidth.value(), m_targetHeight.value());
  });
}

QOOL_NS_END
