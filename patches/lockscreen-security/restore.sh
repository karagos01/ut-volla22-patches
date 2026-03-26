#!/usr/bin/env bash
set -uo pipefail
UID_NUM=$(id -u phablet 2>/dev/null || echo 32011)
sudo gdbus call --system --dest org.freedesktop.Accounts --object-path "/org/freedesktop/Accounts/User${UID_NUM}" --method org.freedesktop.DBus.Properties.Set com.lomiri.AccountsService.SecurityPrivacy EnableLauncherWhileLocked '<true>' >/dev/null 2>&1
sudo gdbus call --system --dest org.freedesktop.Accounts --object-path "/org/freedesktop/Accounts/User${UID_NUM}" --method org.freedesktop.DBus.Properties.Set com.lomiri.AccountsService.SecurityPrivacy EnableIndicatorsWhileLocked '<true>' >/dev/null 2>&1
echo "Lockscreen security restored to stock."
