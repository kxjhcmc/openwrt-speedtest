#
# Copyright (C) 2026 <you>
#
# This is free software, licensed under the MIT License.
#
# Package: speedtest (better-speedtest binary + backend)
#   - Downloads a pinned release of the better-speedtest CLI at build time.
#   - To update the bundled binary, bump PKG_VERSION and PKG_HASH below,
#     then run: make package/speedtest/download V=s
#
include $(TOPDIR)/rules.mk

PKG_NAME:=speedtest
PKG_RELEASE:=2

# ----------------------------------------------------------------------------
# better-speedtest upstream release
# To bump the bundled binary:
#   1. edit PKG_VERSION (upstream tag without the leading 'v')
#   2. replace PKG_HASH with the sha256 of the corresponding
#      better-speedtest-linux-<arch> asset (see SHA256SUMS.txt at that release)
#   3. run:  make package/speedtest/download V=s   (in the SDK)
# ----------------------------------------------------------------------------
PKG_VERSION:=0.0.3
PKG_HASH_amd64:=d035456877a545a8dc47d5bb5c9420531806a98c83c1f0c55b3fc2397529b532
PKG_HASH_386:=d4240d34212388083709c08474cc7c26f400940403b60ddacfa640a2ba80c942

# map OpenWrt target arch -> upstream asset arch
# (this package is intended for x86 targets only)
ifeq ($(ARCH),x86_64)
  BST_ARCH:=amd64
else ifeq ($(ARCH),i386)
  BST_ARCH:=386
else ifeq ($(ARCH),i486)
  BST_ARCH:=386
else ifeq ($(ARCH),i586)
  BST_ARCH:=386
else ifeq ($(ARCH),i686)
  BST_ARCH:=386
else
  # no matching upstream binary; fall back to amd64 and warn
  BST_ARCH:=amd64
endif

PKG_HASH:=$(PKG_HASH_$(BST_ARCH))

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Download/better-speedtest
  URL:=https://github.com/Gaimoydev/better-speedtest/releases/download/v$(PKG_VERSION)/
  FILE:=better-speedtest-linux-$(BST_ARCH)
  HASH:=$(PKG_HASH)
endef
$(eval $(call Download,better-speedtest))

define Package/speedtest
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Multi-source speed test CLI (better-speedtest)
  URL:=https://github.com/Gaimoydev/better-speedtest
  DEPENDS:=
  MAINTAINER:=your@email.example
endef

define Package/speedtest/description
  better-speedtest: a multi-source, cross-platform speed-test CLI.
  This package ships the prebuilt binary only. The Web UI is provided
  by luci-app-speedtest (DEPENDS on this package).
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(DL_DIR)/better-speedtest-linux-$(BST_ARCH) $(PKG_BUILD_DIR)/better-speedtest
	chmod 0755 $(PKG_BUILD_DIR)/better-speedtest
endef

define Build/Compile
	# nothing to compile: the binary is prebuilt
endef

define Package/speedtest/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/better-speedtest $(1)/usr/bin/better-speedtest
	$(INSTALL_DIR) $(1)/usr/libexec/speedtest
	$(INSTALL_BIN) ./files/usr/libexec/speedtest/backend $(1)/usr/libexec/speedtest/backend
	$(INSTALL_DIR) $(1)/etc/better-speedtest
	$(INSTALL_DATA) ./files/etc/better-speedtest/config.json $(1)/etc/better-speedtest/config.json
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/speedtestd $(1)/etc/init.d/speedtestd
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/etc/config/speedtest $(1)/etc/config/speedtest
endef

define Package/speedtest/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
# the runtime config lives on the overlay, make sure it is writable
mkdir -p /etc/better-speedtest
if [ -x /etc/init.d/speedtestd ]; then
	/etc/init.d/speedtestd enable 2>/dev/null || true
	/etc/init.d/speedtestd start 2>/dev/null || true
fi
exit 0
endef

define Package/speedtest/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
if [ -x /etc/init.d/speedtestd ]; then
	/etc/init.d/speedtestd stop 2>/dev/null || true
	/etc/init.d/speedtestd disable 2>/dev/null || true
fi
exit 0
endef

$(eval $(call BuildPackage,speedtest))