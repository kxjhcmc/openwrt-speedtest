#
# Copyright (C) 2026 <you>
#
# LuCI front-end for the speedtest backend.
# This package DEPENDS on the binary provider package "speedtest".
#
# Built as a plain OpenWrt package (no luci feed required): the Lua
# controller/view and the i18n title are installed as static files.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-speedtest
PKG_VERSION:=1.0
PKG_RELEASE:=4

PKG_ARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-speedtest
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Multi-source speed test (Web UI)
  URL:=https://github.com/Gaimoydev/better-speedtest
  DEPENDS:=+speedtest +luci-lua-runtime
  MAINTAINER:=your@email.example
endef

define Package/luci-app-speedtest/description
  Speedtest.net-style Web UI for the better-speedtest multi-source speed-test
  CLI. Runs the binary on demand (click GO), streams the NDJSON progress into
  a live gauge and results cards.
endef

define Build/Prepare
	# static files only
endef

define Build/Compile
	# static files only
endef

define Package/luci-app-speedtest/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./root/usr/lib/lua/luci/controller/speedtest.lua \
		$(1)/usr/lib/lua/luci/controller/speedtest.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/speedtest
	$(INSTALL_DATA) ./root/usr/lib/lua/luci/view/speedtest/index.htm \
		$(1)/usr/lib/lua/luci/view/speedtest/index.htm
endef

define Package/luci-app-speedtest/postinst
#!/bin/sh
# IPKG_INSTROOT: opkg (<= 24.10), PKG_INSTROOT: apk (>= 25.12)
[ -n "$${IPKG_INSTROOT}$${PKG_INSTROOT}" ] && exit 0
# refresh the LuCI menu cache so the new entry appears immediately
rm -f /tmp/luci-indexcache* /tmp/luci-modulecache/* 2>/dev/null || true
exit 0
endef

$(eval $(call BuildPackage,luci-app-speedtest))