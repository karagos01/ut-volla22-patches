#!/usr/bin/env bash
# Fast unlock — reduces PIN unlock from ~3s to ~150ms
# Volla Phone 22 / UT 24.04
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

# Backup originals
for f in /etc/pam.d/lightdm /etc/pam.d/common-auth /etc/pam.d/common-session /usr/share/lomiri/Greeter/GreeterView.qml; do
    [ -f "$f" ] && [ ! -f "${f}.orig" ] && sudo cp "$f" "${f}.orig"
done

# Copy phablet account from extrausers to /etc so pam_unix can find it
grep -q "^phablet:" /etc/shadow 2>/dev/null || {
    sudo sh -c 'grep phablet /var/lib/extrausers/passwd >> /etc/passwd' 2>/dev/null
    sudo sh -c 'grep phablet /var/lib/extrausers/shadow >> /etc/shadow' 2>/dev/null
}

# PAM: minimal lightdm auth, nodelay, no fscrypt
sudo install -m 0644 "$DIR/lightdm" /etc/pam.d/lightdm
sudo install -m 0644 "$DIR/common-auth" /etc/pam.d/common-auth
sudo install -m 0644 "$DIR/common-session" /etc/pam.d/common-session

# Greeter: instant transitions (no fade)
sudo install -m 0644 "$DIR/GreeterView.qml" /usr/share/lomiri/Greeter/GreeterView.qml

echo "Fast unlock applied."
