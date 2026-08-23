# OpenWrt build for Xiaomi MiWiFi Mini (R4C)

Automated build of OpenWrt 24.10 firmware for the Xiaomi MiWiFi Mini
(`ramips/mt7620`, MediaTek MT7620A) via GitHub Actions. All proxy
software packages are removed; only base, network, storage, management
and LuCI applications are included.

## Files

- `.github/workflows/build.yml` — GitHub Actions build workflow
- `.config` — OpenWrt configuration (target device + non-proxy packages)
- `feeds.conf` — official 24.10 feeds + non-proxy third-party feeds
- `diy-part1.sh` — runs after source clone, before feeds
- `diy-part2.sh` — runs after config generation, before compile

## How to build

1. Push this folder to a GitHub repository.
2. Go to **Actions → Build OpenWrt for Xiaomi MiWiFi Mini**.
3. Click **Run workflow** (optionally change `repo_branch`).
4. When finished, download the `openwrt-miwi-mini-firmware` artifact.
5. Flash `*-squashfs-sysupgrade.bin` via sysupgrade (no factory image
   is produced for this device; use Breed/PandoraBox for first flash).

## Notes

- GitHub runner has 14 GB disk and a 6h job timeout; the workflow clears
  space, caches `dl/` and `ccache`, and uses a shallow clone to cope.
- OpenWrt 24.10 uses firewall4/nftables, so `kmod-ipt-fullconenat` is
  intentionally omitted; software flow offloading is enabled instead.
- `luci-theme-argon`, `luci-app-vlmcsd`, `luci-app-vsftpd` and Lean
  LuCI apps come from third-party feeds and may need individual testing
  on the 24.
