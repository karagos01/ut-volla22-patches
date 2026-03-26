# Fast Unlock

Reduces lockscreen PIN unlock from ~3 seconds to ~150ms.

## Problem

Stock UT 24.04 lockscreen has a ~3s delay after entering correct PIN due to:
- `pam_fscrypt.so` in common-session timing out (`setting groups: operation not permitted`)
- `@include common-auth` chain going through `pam_succeed_if` + `pam_extrausers` + slow `pam_unix`
- `@include common-account` adding `pam_acct_mgmt` overhead
- Greeter fade-out animation adding perceived delay

## Fix

1. **lightdm PAM** — minimal auth: `pam_nologin` → `pam_unix nodelay` → `pam_permit`, no common-auth/account/session includes
2. **phablet in /etc/shadow** — copied from `/var/lib/extrausers/shadow` so `pam_unix` works directly
3. **common-auth** — `nodelay` added to `pam_unix`
4. **common-session** — `pam_fscrypt` removed
5. **GreeterView.qml** — fade animations replaced with instant transitions

## Measured timing

- `respond()` → `onLoginSuccess`: ~150ms (PAM auth)
- `onLoginSuccess` → screen unlocked: instant (lightdm activates session in background)
