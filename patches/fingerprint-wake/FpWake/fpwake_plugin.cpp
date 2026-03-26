#include "fpwake_plugin.h"
#include <QQmlEngine>
#include <QDBusInterface>
#include <QDBusConnection>
void FpWake::wakeScreen() {
    QDBusInterface iface("com.canonical.Unity.Screen",
                         "/com/canonical/Unity/Screen",
                         "com.canonical.Unity.Screen",
                         QDBusConnection::systemBus());
    if (iface.isValid()) iface.call("keepDisplayOn");
}
void FpWakePlugin::registerTypes(const char *uri) {
    qmlRegisterSingletonType<FpWake>(uri, 0, 1, "FpWake",
        [](QQmlEngine *, QJSEngine *) -> QObject * { return new FpWake; });
}
