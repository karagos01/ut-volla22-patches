#!/usr/bin/env bash
set -uo pipefail
UID_NUM=$(id -u phablet 2>/dev/null || echo 32011)

# Disable launcher on lockscreen (prevents focus steal)
sudo gdbus call --system --dest org.freedesktop.Accounts \
    --object-path "/org/freedesktop/Accounts/User${UID_NUM}" \
    --method org.freedesktop.DBus.Properties.Set \
    com.lomiri.AccountsService.SecurityPrivacy EnableLauncherWhileLocked '<false>' >/dev/null 2>&1

# Disable indicators/quick bar on lockscreen
sudo gdbus call --system --dest org.freedesktop.Accounts \
    --object-path "/org/freedesktop/Accounts/User${UID_NUM}" \
    --method org.freedesktop.DBus.Properties.Set \
    com.lomiri.AccountsService.SecurityPrivacy EnableIndicatorsWhileLocked '<false>' >/dev/null 2>&1

echo "Lockscreen security applied (no launcher, no indicators)."
