#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QTranslator>

int main(int argc, char* argv[]) {
  QGuiApplication app(argc, argv);

  QTranslator translator;
  if (translator.load(QLocale(), "qoolexample", "_", ":/i18n"))
    app.installTranslator(&translator);

  QQmlApplicationEngine engine;
  engine.addImportPath(QStringLiteral("qml"));

  QObject::connect(
    &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
    []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("QoolUIExample", "Main");

  return app.exec();
}
