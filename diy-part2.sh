#!/usr/bin/env bash
# Runs after config generation, before compilation.
# Place custom package tweaks or sed edits to .config here.
set -e

# 仅安装 .config 实际需要的 Lean 系 LuCI 包，避免 feeds install -a 全装 Lean 源时因
# 版本/依赖不兼容而报错（与本地成功构建保持一致）。
cd "$(dirname "$0")/openwrt"
./scripts/feeds install -p leanluci luci-app-vsftpd luci-app-accesscontrol \
  luci-app-arpbind luci-app-autoreboot luci-app-filetransfer || true

# 防御：本项目基于官方 OpenWrt 24.10（内核 6.6），Lean 的 turboacc 内核模块在此内核
# 上不兼容，明确拒绝误选 turboacc / sfe / shortcut-fe 相关包，保证产出干净。
echo "diy-part2: ensure no turboacc/sfe packages selected"
for p in luci-app-turboacc turboacc kmod-turboacc kmod-fast-classifier kmod-shortcut-fe kmod-sfe kmod-sfe-cm kmod-sfe-nft; do
  sed -i "/^CONFIG_PACKAGE_${p}=y/d" ../.config || true
done

# 官方线无 default-settings 包，编译期注入默认中文语言，使刷入后 LuCI 即为简体中文。
echo "diy-part2: inject default Chinese language for LuCI"
mkdir -p files/etc/config
cat > files/etc/config/luci <<'EOF'
config core main
	option lang 'zh_cn'
	option mediaurlbase '/luci-static/bootstrap'
	option resourcebase '/luci-static/resources'

config extern flash_keep
	list uci '/etc/config/luci'

config internal languages
	list en 'English'
	list zh_cn '简体中文'

config internal sauth
	list sessionpath '/tmp/luci-sessions'

config internal ccache
	list mediaurlbase '/luci-static/bootstrap'
EOF

# 官方 24.10 该机型 DTS 未给蓝灯设启动触发，导致开机无蓝色活动指示灯（常亮黄/橙）。
# 用用户态方式在开机后让蓝灯以 heartbeat 触发规律闪烁，复现 lede 的"蓝灯指示启动/运行"。
echo "diy-part2: inject blue LED heartbeat indicator"
mkdir -p files/etc
cat > files/etc/rc.local <<'EOF'
# 开机后让状态蓝灯以 heartbeat 规律闪烁（官方 24.10 DTS 未设启动触发，此处补偿）
for d in /sys/class/leds/*; do
  name=$(basename "$d")
  case "$name" in
    blue:* | *blue* | led_blue*) echo heartbeat > "$d/trigger" 2>/dev/null ;;
  esac
done
exit 0
EOF

echo "diy-part2: done"
