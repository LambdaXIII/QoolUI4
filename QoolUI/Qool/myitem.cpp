#include "myitem.h"

#include <QPainter>

MyItem::MyItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    // By default, QQuickItem does not draw anything. If you subclass
    // QQuickItem to create a visual item, you will need to uncomment the
    // following line and re-implement updatePaintNode()

    // setFlag(ItemHasContents, true);
}

void MyItem::paint(QPainter *painter)
{
    QPen pen(QColorConstants::Red, 2);
    QBrush brush(QColorConstants::Red);

    painter->setPen(pen);
    painter->setBrush(brush);
    painter->drawRect(0, 0, 100, 100);
}

MyItem::~MyItem() {}

QString MyItem::greeting() const {
  return "Hello World!";
}
