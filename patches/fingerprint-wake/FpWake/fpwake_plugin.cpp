#include "fpwake_plugin.h"
#include <QQmlEngine>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QProcess>

void FpWake::wakeScreen() {
    QDBusInterface iface("com.canonical.Unity.Screen", "/com/canonical/Unity/Screen",
                         "com.canonical.Unity.Screen", QDBusConnection::systemBus());
    if (iface.isValid()) iface.call("keepDisplayOn");
}

void FpWake::setBrightness(int value) {
    QDBusInterface iface("com.canonical.Unity.Screen", "/com/canonical/Unity/Screen",
                         "com.canonical.Unity.Screen", QDBusConnection::systemBus());
    if (iface.isValid()) iface.call("setUserBrightness", value);
}

void FpWake::openSettings() {
    QProcess::startDetached("lomiri-app-launch", QStringList() << "lomiri-system-settings");
}

QString FpWake::wifiSsid() {
    QProcess p; p.start("nmcli", {"-t", "-f", "active,ssid", "dev", "wifi"});
    p.waitForFinished(2000);
    for (const QString &l : QString(p.readAllStandardOutput()).split('\n'))
        if (l.startsWith("yes:")) return l.mid(4).trimmed();
    return "";
}

QString FpWake::btDevice() {
    QProcess p; p.start("bluetoothctl", {"devices", "Connected"});
    p.waitForFinished(2000);
    QString out = p.readAllStandardOutput().trimmed();
    if (!out.isEmpty()) {
        int i = out.indexOf(' ', out.indexOf(' ') + 1);
        if (i > 0) return out.mid(i + 1).trimmed();
    }
    return "";
}

void FpWake::wifiToggle() {
    bool on = wifiEnabled();
    QProcess::startDetached("nmcli", {"radio", "wifi", on ? "off" : "on"});
}

void FpWake::btToggle() {
    bool on = btEnabled();
    QProcess::startDetached("bluetoothctl", {on ? "power" : "power", on ? "off" : "on"});
}

bool FpWake::wifiEnabled() {
    QProcess p; p.start("nmcli", {"radio", "wifi"});
    p.waitForFinished(2000);
    return p.readAllStandardOutput().trimmed() == "enabled";
}

bool FpWake::btEnabled() {
    QProcess p; p.start("bluetoothctl", {"show"});
    p.waitForFinished(2000);
    return p.readAllStandardOutput().contains("Powered: yes");
}

QVariantList FpWake::wifiNetworks() {
    QVariantList list;
    QProcess p; p.start("nmcli", {"-t", "-f", "active,signal,ssid", "dev", "wifi"});
    p.waitForFinished(3000);
    for (const QString &l : QString(p.readAllStandardOutput()).split('\n')) {
        QStringList parts = l.split(':');
        if (parts.size() >= 3 && !parts[2].isEmpty()) {
            QVariantMap net;
            net["active"] = parts[0] == "yes";
            net["signal"] = parts[1].toInt();
            net["ssid"] = parts[2];
            list.append(net);
        }
    }
    return list;
}

void FpWake::wifiConnect(const QString &ssid) {
    QProcess::startDetached("nmcli", {"con", "up", ssid});
}

void FpWakePlugin::registerTypes(const char *uri) {
    qmlRegisterSingletonType<FpWake>(uri, 0, 1, "FpWake",
        [](QQmlEngine *, QJSEngine *) -> QObject * { return new FpWake; });
}
