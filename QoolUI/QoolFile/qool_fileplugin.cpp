#include "qool_fileplugin.h"

#include "qool_fileicon_imageprovider.h"
#include "qoolcommon/debug.hpp"

#include <QQmlEngine>

Qool_FilePlugin::Qool_FilePlugin(QObject* parent)
  : QQmlEngineExtensionPlugin { parent } {
  volatile auto registration = &qml_register_types_qool_file;
  Q_UNUSED(registration)
}

void Qool_FilePlugin::initializeEngine(
  QQmlEngine* engine, const char* uri) {
  volatile auto registration = &qml_register_types_qool_file;
  Q_UNUSED(registration)

  engine->addImageProvider(QOOL_NS::FileIconImageProvider::schema(),
    new QOOL_NS::FileIconImageProvider);

  xInfoQ << "QoolFileIconImageProvider installed.";
}

void qml_register_types_qool_file() {
}
