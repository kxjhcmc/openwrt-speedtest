# openwrt-speedtest — OpenWrt 多源测速插件

基于 [Gaimoydev/better-speedtest](https://github.com/Gaimoydev/better-speedtest) 的 OpenWrt 插件。在 LuCI 的 **网络 → 网络测速** 页面新增一个大圆 **GO** 按钮,点击后才启动底层二进制,实时把 NDJSON 进度流渲染成 Speedtest 风格仪表盘、吞吐曲线和结果卡片。

本仓库包含两个独立的 OpenWrt 包:

- **`speedtest`** —— 底层二进制(better-speedtest)+ 后端控制脚本,编译时从上游 Release 下载锁定版本的二进制并校验 SHA-256。
- **`luci-app-speedtest`** —— LuCI 前端,`DEPENDS` 依赖 `speedtest` 包。

## 目录结构

```
openwrt-speedtest/
├── speedtest/                    # 二进制提供包
│   ├── Makefile                  # 编译时按锁定的版本下载 better-speedtest 二进制
│   └── files/
│       ├── .../backend           # start/stop/status/log/nodes/ip 后端
│       ├── .../config.json       # 测速引擎配置
│       └── .../speedtestd        # 服务 init 脚本
└── luci-app-speedtest/           # LuCI 界面包
    ├── Makefile                  # DEPENDS:=+speedtest +luci-lua-runtime
    └── root/usr/lib/lua/luci/    # controller + view
```

## 支持的架构

| 架构 | 状态 | 说明 |
|------|------|------|
| **x86_64 (amd64)** | ✅ 支持 | 官方默认目标,`speedtest/Makefile` 已内置 `amd64` 二进制映射 |
| **x86 (i386/i486/i586/i686)** | ✅ 支持 | `Makefile` 已含 386 资产映射,需用 x86(generic) SDK 编译 |
| **arm (armv7/aarch64 等)** | ⚠️ 源码未做 | 理论上可以支持,但本仓库**尚未**提供 ARM 二进制,也未接入 ARM 的 `PKG_HASH` 映射 |

> **关于 ARM 支持:** 目前 `speedtest` 包的 `Makefile` 只针对 x86 目标做了二进制映射,非 x86 架构会回退到 amd64 二进制(无法在 ARM 上运行)。若要让它支持 ARM,需要:
> 1. 在 `speedtest/Makefile` 的 `Download/better-speedtest` 中为 ARM 架构(`armv7` / `aarch64`)添加对应的 `PKG_HASH_armv7` / `PKG_HASH_arm64` 等哈希,并在 `ifeq` 分支里把 `BST_ARCH` 映射到上游 `better-speedtest-linux-armv7` / `arm64` 资产;
> 2. 在 `Package/speedtest` 里用 `DEPENDS` 声明对应架构(如 `+@TARGET_armv7.0`),避免在非目标架构上误选;
> 3. 确保底层二进制 `better-speedtest` 有对应 ARM 平台的预编译版本。
>
> 上游 [better-speedtest](https://github.com/Gaimoydev/better-speedtest) 已发布 ARM 资产,补齐映射后即可支持 ARM 设备。

## 融合进 OpenWrt 编译

本项目是**标准 OpenWrt 包**,可以融入你自建的 OpenWrt 源码树进行编译。有两种方式。

### 作为 feeds 链接(推荐,开发调试用)

把本仓库作为一个自定义 feeds 链接进 OpenWrt 源码的 `feeds.conf`。

1. 进入 OpenWrt 源码目录,编辑 `feeds.conf`，加入以下内容：

   ```
   src-link speedtest_owrt https://github.com/kxjhcmc/openwrt-speedtest
   ```


2. 更新并安装 feeds:

   ```sh
   ./scripts/feeds update speedtest_owrt
   ./scripts/feeds install -p speedtest_owrt
   ```

3. 进入配置界面,勾选要编译的包:

   ```sh
   make menuconfig
   # 路径: Network → speedtest (better-speedtest CLI)
   # 路径: LuCI → Applications → luci-app-speedtest (Web UI)
   ```

4. 编译:

   ```sh
   make package/speedtest/compile V=s
   make package/luci-app-speedtest/compile V=s
   ```

   产物位于 `bin/packages/<target>/speedtest_owrt/`。

## 安装到路由器

编译出的包是用 SDK 私钥本地签名的,路由器默认不信任,需加 `--allow-untrusted`:

```sh
apk update
apk add --allow-untrusted /tmp/speedtest-0.0.3-r2.apk
apk add --allow-untrusted /tmp/luci-app-speedtest-1.0-r4.apk
```

若路由器缺少依赖 `libc`,可先 `apk add libc`。

> 也可把该 SDK 的 `public-key.pem` 加入路由器 `/etc/apk/keys/`,之后 `apk add` 就无需 `--allow-untrusted`。

## 使用

1. 选择 **测速源**(自动 / 全球网测 / CDN / Speedtest.net)、**方向**(双向 / 仅下行 / 仅上行)、**时长**、**多源并发**,可填 **指定节点** 关键字。
2. 点击 **GO** 开始:此时才运行 `better-speedtest test --json`。
3. 页面实时轮询 `/tmp/speedtest/run.ndjson`,驱动仪表指针、吞吐曲线与延迟/下载/上传结果卡。
4. 可点 **重新测速**;测速期间可中断(再次点击 GO 等同停止)。

## 升级底层二进制

编辑 `speedtest/Makefile`:

```make
PKG_VERSION:=0.0.4          # 改成上游新 tag
PKG_HASH_amd64:=<新 SHA256>   # 替换为对应资产的 sha256
```

然后重新 `./build.sh`,会从新 release 拉取二进制并校验哈希后再打包。

## 说明

- 当前**仅支持 x86(amd64 / i386)** 目标;ARM 架构源码尚未接入(见上方「支持的架构」)。
- 测速命令直接由 LuCI(root 会话)以 `setsid` 方式后台执行,避免 CGI 退出时被终止。
- 节点探测、定位等请求走公网,请保证路由器有可用外网。
