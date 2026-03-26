# Ubuntu Touch Patches — Volla Phone 22

Device-specific patches for Volla Phone 22 (mimameid / MT6768) running Ubuntu Touch 24.04.

## Install

```bash
git clone https://github.com/karagos01/ut-volla22-patches ~/.local/share/ut-patches
~/.local/share/ut-patches/install.sh
```

## Patches

Each patch lives in `patches/<name>/` with `apply.sh`, `restore.sh`, and `README.md`.

| Patch | Description |
|-------|-------------|
| `fast-unlock` | PIN unlock in ~150ms instead of ~3s |

## Adding new patches

Create `patches/<name>/apply.sh` — the installer auto-discovers it. Add `restore.sh` for rollback and `README.md` for docs.

## Device

- Volla Phone 22 (MT6768 / mimameid)
- Ubuntu Touch 24.04-1.x
- Lomiri 0.5.0
