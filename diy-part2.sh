#!/usr/bin/env bash
# Runs after config generation, before compilation.
# Place custom package tweaks or sed edits to .config here.
set -e

# 仅安装 .config 实际需要的 Lean 系 LuCI 包，避免 feeds install -a 全装 Lean 源时因
# 版本/依赖不兼容而报错（与本地成功构建保持一致）。
cd "$(dirname "$0")/openwrt"
./scripts/feeds install -p leanluci luci-app-vsftpd luci-app-accesscontrol \
  luci-app-arpbind luci-app-autoreboot luci-app-filetransfer || true

echo "diy-part2: done"
