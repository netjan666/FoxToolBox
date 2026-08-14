> 基于佬王综合工具箱（ssh_tool）修改自用

# 🦊 FoxToolBox

> VPS 维护搭建工具箱 —— 一款开箱即用、中英双语、彩色菜单的服务器管理脚本

## ✨ 功能亮点

- 🎨 彩色菜单 + 中英双语，交互友好
- 🚀 一行命令安装，无需手动配置
- 🔧 覆盖服务器管理全场景：信息查看、系统更新、组件安装、面板部署、性能测试
- 📦 自动创建 `k` 快捷命令，一个字母随时启动
- ☁️ 支持 Docker、1Panel、AList、青龙面板等热门应用一键部署

## 🚀 快速安装

**一键运行（短链接版，推荐）：**

```bash
bash <(curl -Ls https://tinyurl.com/23hc2sol)
```

**完整版命令：**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/netjan666/FoxToolBox/main/fox_toolbox.sh)
```

**首次运行后**，脚本会自动在系统中创建快捷命令 `k`，以后只需：

```bash
k
```

## 📖 使用说明

### 快捷命令

| 命令 | 说明 |
|:---:|:---|
| `k` | 一键启动 FoxToolBox（在线获取最新版） |
| `K` | 同款大写版 |

### 自定义别名（可选）

想用更顺口的名字，在 `~/.bashrc` 中添加：

```bash
alias fox='bash <(curl -Ls https://tinyurl.com/23hc2sol)'
```

然后执行 `source ~/.bashrc`，之后输入 `fox` 即可。

## 🗂️ 菜单总览

```
═══════════════════════════════════
          🔥 FOXTOOLBOX 🔥
═══════════════════════════════════
 1. 本机信息        5. BBR 管理
 2. 系统更新        6. Docker 管理 ▶
 3. 系统清理        7. 面板工具 ▶
 4. 组件管理 ▶      8. 测试脚本 ▶
 9. 系统工具 ▶     11. 开发环境 ▶
10. 环境信息
88. 退出脚本
═══════════════════════════════════
```

### 子菜单功能

| 菜单 | 功能 |
|:---:|:---|
| **组件管理** | 16+ 常用工具一键安装/卸载（curl、htop、tmux、ffmpeg 等） |
| **Docker 管理** | Docker 安装/卸载、容器管理、镜像管理、清理 |
| **面板工具** | 1Panel、AList、Portainer、UptimeKuma、Memos、NPM、青龙面板 |
| **测试脚本** | ChatGPT 解锁检测、流媒体检测、三网测速、回程路由、yabs/bench、融合怪 |
| **系统工具** | 修改密码、SSH 端口、防火墙、软件源、定时任务、用户管理、Swap、时区 |
| **开发环境** | Python / Node.js / Go / Java 一键安装卸载 |

## 🔄 更新方式

每次运行都会自动从 GitHub 拉取最新版脚本，无需手动更新。

也可以手动强制更新：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/netjan666/FoxToolBox/main/fox_toolbox.sh)
```

## 📋 系统要求

- 操作系统：Ubuntu / Debian / CentOS / 其他主流 Linux 发行版
- 权限：需要 root 用户运行
- 依赖：curl（大多数系统已预装）

## ⚠️ 免责声明

本工具仅供学习与合法用途使用。使用本脚本产生的任何后果由使用者自行承担。

## 📄 许可证

MIT License

---

🌟 **如果觉得好用，欢迎 Star 支持！**