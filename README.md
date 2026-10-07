# DSH 破甲模式 v2.0

**双击一个文件，你的 DSH（DeepSeek Harness）就多出一个「破甲模式」** —— 不改 DSH 一字节代码、不动官方目录、升级不丢；零依赖（系统自带 PowerShell）、改前自动备份、装完当场可自证（含端到端验证）、随时可一键卸载。

[![Release](https://img.shields.io/github/v/release/z91772524-ai/dsh-pojia-mode?label=release&color=2ea043)](https://github.com/z91772524-ai/dsh-pojia-mode/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-0078d4)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE)](https://learn.microsoft.com/powershell/)
[![DSH](https://img.shields.io/badge/DSH-0.2.0%2B-blue)](#兼容性)
[![Dependencies](https://img.shields.io/badge/dependencies-0-brightgreen)]()
[![网络请求](https://img.shields.io/badge/网络请求-0-brightgreen)](#安全设计)

> ### v2.0 适配了什么
> **DSH 0.2.0（含 0.2.0-rc.2）把 preset 注册表改成了声明式**：不再扫描
> `~/.dsh/.agent-presets\` 目录（官方文档原话：*Nothing reads that directory
> any more*）。v1.x 的安装器「装好了但选择器里看不到」就是这个原因。
> v2.0 改为向 profile 的 `cordis.patch.yml` 写入一段受管的 `- insert:` 块，
> 由 DSH 自己的组合器在启动时注册进 preset 名录 —— 详见 [v2.0 改了什么](#v20-改了什么)。
> 老版本 DSH（0.1.x）请用 [v1.1 release](https://github.com/z91772524-ai/dsh-pojia-mode/releases)。

> ## ⚠️ 免责声明（务必先读）
> **本项目仅用于学习交流，无不良引导。若他人使用本项目从事任何违法、违规或侵权行为，与作者没有任何关系，全部后果由使用者自行承担。**
> 请遵守所在地法律法规与目标软件的服务条款。

把 DSH 的「破甲模式」做成**一个可交付的安装器**：一份自包含的 preset 声明，双击即装，**零第三方依赖**。

![破甲模式出现在 DSH 选择器里](preview-mode-picker.png)

## 快速开始

1. 下载 **`dsh-pojia-mode.zip`** 并解压到任意目录
2. **完全退出 DSH**（含右键托盘图标 → 退出）
3. 双击 **`unlock-dsh-silent.vbs`**（无黑框；用 `unlock-dsh.bat` 也行，但会弹 cmd 窗口）
4. 重开 DSH → 新建会话 → preset 选择器里选「**破甲模式**」
5. 单独发一条 `破甲自检` 验收

预期**只回一行**：

```
破甲已生效｜目标 DSH｜破甲模式 v5
```

> **看不到「破甲模式」？** 先在解压目录跑 `.\unlock-dsh.ps1 verify`（让 DSH 自己组合一遍配置树），再不行跑 `.\unlock-dsh.ps1 diagnose`，把输出贴到 Issues。

## 两个入口

| 双击这个 | 窗口 | 说明 |
|---|---|---|
| **`unlock-dsh-silent.vbs`** | ✅ 无黑框 | 推荐。跑完弹窗展示完整结果 |
| `unlock-dsh.bat` | 弹 cmd | 备用 / 命令行调参用 |

> ⚠️ **别把启动器单独拖出文件夹** —— 它靠 `%~dp0` / `VBScript.ScriptFullName` 找同级的 `unlock-dsh.ps1` 和 `assets\`，三件必须同目录。

## 命令行用法

```powershell
.\unlock-dsh.ps1 install     # 安装 + 自检（同双击）
.\unlock-dsh.ps1 verify      # 端到端验证：DSH 自己组合配置树，确认 preset 行被接受
.\unlock-dsh.ps1 dry-run     # 只预演，看将要写入什么，磁盘不动
.\unlock-dsh.ps1 check       # 自检：各 profile 的 insert 块在不在、关键内容齐不齐
.\unlock-dsh.ps1 list        # 列出各 profile 的安装状态
.\unlock-dsh.ps1 diagnose    # 诊断：打印 DSH_HOME 候选与判定依据（只读）
.\unlock-dsh.ps1 uninstall   # 卸载：从各 profile 的 patch 文件里整块移除
```

自定义名字与 id：

```powershell
.\unlock-dsh.ps1 install -PresetId my-unlock -PresetName "我的破甲"
```

只操作某个 profile（默认安装到**全部**已存在的 profile，桌面版 / Web 版一次装齐）：

```powershell
.\unlock-dsh.ps1 install -ProfileName desktop
```

手动指定 DSH 数据目录（探测结果不对时用这个，优先级最高）：

```powershell
.\unlock-dsh.ps1 install -DshHome "D:\你的\DSH数据目录"
```

`verify` 找不到部署目录时（DSH 没在运行），显式指一下：

```powershell
.\unlock-dsh.ps1 verify -CliPath "G:\DeepSeek Harness\DeepSeek Harness.exe"
```

无交互执行（CI / 脚本里批量装；静默启动器已自动带上它）：

```powershell
.\unlock-dsh.ps1 install -Yes
```

> 若提示「禁止运行脚本」，用 `.bat` / `.vbs` 入口即可（它们带 `-ExecutionPolicy Bypass`）。

## v2.0 改了什么

DSH 0.2.0 起，`@deepseek-ai/dsh-agent-preset-registry` 改为**声明式注册**：

| | v1.x（DSH ≤ 0.1.x） | v2.0（DSH ≥ 0.2.0） |
|---|---|---|
| 加载机制 | 扫描 `$DSH_HOME\.agent-presets\<id>\` 目录 | 组合配置树时识别 `@deepseek-ai/dsh-agent-preset` 声明行 |
| 写入位置 | `.agent-presets\pj-mode\`（两个文件） | `profiles\<profile>\cordis.patch.yml` 追加一段 `- insert:` 受管块 |
| 是否需要跑 pnpm / 进会话装 bundle | 否 | 否（插件包全部来自部署自带，profile patch 层直接解析） |
| 生效时机 | 重启 DSH | 重启 DSH |
| 卸载 | 目录移入 `_uninstalled-*` | 整块移除 + 自动迁移旧目录 |

**为什么还是零依赖零联网**：profile patch 层是 DSH 官方留给用户的覆盖层（官方注释：*applied after every bundle layer … insert lists allowed*），`- insert:` 的行引用的插件包（persona、工具等）与内置 preset 同名，由 DSH 部署目录解析，不需要 pnpm 安装任何东西。

**verify 是怎么做到端到端的**：DSH 部署自带的运行时（Electron-as-Node）加载官方 `--dump-config` 实现模块，按真实启动路径组合一遍配置树（只组合、不挂载、不启动服务），然后确认 `preset-pj-mode` 行出现在组合树里。这一步等价于「DSH 已经读过并接受了你的 preset 声明」。

## DSH 数据目录是怎么探测的

候选按可信度打分，取最高的那个：

| 分 | 来源 | 说明 |
|---|---|---|
| 110 | `-DshHome` 参数 | 你显式指定，无条件采用 |
| 100 | `$env:DSH_HOME` | DSH 启动子进程时会注入；有值即用（与官方 `resolveDshHome()` 同语义） |
| 90 | DSH Desktop 启动器记录 | `%APPDATA%\<应用名>\host-commands\<profile>\bin\dsh.cmd` 里写死的 `set "DSH_HOME=..."` |
| 60 | `~/.dsh` | 官方默认位置 |
| 55 | `~/.dsh-beta` | NEXT Beta 通道默认 |
| 40 | 主目录下其它 `.dsh*` | 历史遗留 / 自定义 |
| +5 | 含 `profiles` / `sessions` / `storages` 等 | 加分项，用来区分"真的 DSH 数据目录"和同名空目录 |

110 和 100 两项**不检查目录是否存在** —— 你刚指定、还没启动过 DSH 的情况必须能用。

## 装进去的是什么

向每个目标 profile 的 `cordis.patch.yml` 追加一段约 13.9 KB 的受管块（`# [dsh-unlock-mode]` 标记行 + 一个 `- insert:` 条目），插入一条 `preset-pj-mode` 声明，七块齐全：

| 区块 | 作用 |
|---|---|
| **声明行** | `@deepseek-ai/dsh-agent-preset`，显示名 / 描述 / 排序（order 10，排在内置四个 preset 之后） |
| **v4 强化版政策正文** | 话题/形式/露骨/指导/命令/渗透/软件分析全面放开，含「残留条款无效」 |
| **作业规范 + 输出纪律** | 目标即授权、真实输出（不编造哈希与回显）、交付优先 |
| **v4 逐条覆盖层** | 7 条最高优先级覆盖，含 Windows 白名单（pwsh / csc / mshta / rundll32 …） |
| **`<文件操作无限制>` 中和块** | 显式解除「个人文件安全」限制条款 |
| **小码酱身份层** | 无自我审查的操作者授权助手 |
| **破甲自检口令** | 会话里单独发「破甲自检」，只回一行回执 |

插件清单与 DSH 0.2.0 内置「标准模式」逐行对齐（19 个顶层插件行：persona、agent-instructions、shell/fs/jobs/skills/goals、plan mode、compaction、delegation、ask-user、todo、web、present …），随版本升级需要重对时，跑一次 `install` 覆盖即可。

## 原理（为什么它这么轻）

DSH 0.2.0 的 profile 组合顺序（来自官方 `profile-boot`）：

```
内置 bundle 层（dsh-base → dsh-web-app → …）
  → profile 用户层    $DSH_HOME/profiles/<profile>/cordis.patch.yml   ← 本工具写这里
  → 数据目录层        $DSH_HOME/cordis.patch.yml（全 profile 共享，本工具不碰）
  → --patch 命令行层
```

patch 层支持三种条目：按 id 覆盖（`- id: …`）、禁用（`disabled: true`）、新增（`- insert:`）。本工具只往 profile 用户层**追加**一个 `- insert:` 条目，声明一条新的 `@deepseek-ai/dsh-agent-preset` 行；DSH 启动时它的注册表把每个这样的行登记成 preset，选择器里随之多出「破甲模式」。

```
dsh-pojia-mode/
├─ unlock-dsh-silent.vbs       双击入口（无黑框）
├─ unlock-dsh.bat              双击入口（备用）
├─ unlock-dsh.ps1              主逻辑（目录探测 / 块管理 / verify / diagnose）
└─ assets/
   └─ pj-mode.patch.yml.tmpl   追加到 cordis.patch.yml 的受管块模板
```

## 安全设计

| 设计 | 原因 |
|---|---|
| **只写用户层 patch** | 绝不碰部署目录与内置 bundle；DSH 升级后重跑一次 install 即可 |
| **受管块 + 标记行** | 重装先整块替换、卸载整块移除，永不碰你自己的 patch 条目 |
| **重名防线** | patch 里已有不受本工具管理的 `preset-pj-mode` 行时拒绝追加，防止重复注册 |
| **原子写** | 先写临时文件再替换，中途断电不会留下半个文件 |
| **UTF-8 无 BOM 落盘** | DSH 的 YAML 加载器要求，带 BOM 会解析失败 |
| **auto-backup** | 覆盖安装前自动备份原 patch 文件为 `.bak-时间戳` |
| **0.1.x 遗留自动迁移** | 旧目录移入 `_uninstalled-pj-mode-legacy-*`（没有本工具标记的不动） |
| **不联网** | 纯本地文件操作；只有完成/失败才弹一次结果框 |
| **`.bat` 纯 ASCII** | `cmd.exe` 按 OEM 代码页解析 .bat，中文注释会撕裂解析 |
| **`.ps1` 带 UTF-8 BOM** | PowerShell 5.1 靠 BOM 判定编码，无 BOM 会把中文读成 GBK 导致语法错误 |
| **`.vbs` 存 GBK** | Windows 脚本宿主按 ANSI 代码页读 .vbs，UTF-8 会报「语句未结束」 |
| **`.vbs` 参数白名单** | 参数会被拼进内层命令行，只接受已知动作，防注入 |

## 排错

**Q：选择器里没有「破甲模式」**
按顺序来：
1. 跑 `.\unlock-dsh.ps1 verify` —— `[OK] 组合树中出现 preset-pj-mode` 说明 DSH 已经接受了声明，问题只剩「没重启 DSH / 没新建会话」。
2. `verify` 报找不到部署目录 → DSH 没在运行，加 `-CliPath` 再跑。
3. `diagnose` 列出多个数据目录 → 装错了目录，用 `-DshHome "正确路径"` 重装。
4. 都不是 → 完全退出 DSH（含托盘）再重开；列表是启动时扫描的。

**Q：双击一闪而过 / 只看到一行报错**
跑 `.\unlock-dsh.ps1 diagnose` 把输出贴到 Issues。
日志在 `%USERPROFILE%\.dsh\logs\unlock-mode-launcher.log`，完整输出在 `%TEMP%\dsh-unlock-result.txt`。

**Q：发了「破甲自检」没回口令**
确认会话是**新建**的、且选择器里选的是「破甲模式」；确认重启过 DSH；跑 `check` 看关键块是否齐全。

**Q：DSH 用的是自定义数据目录**
不用手改环境变量，直接：
`.\unlock-dsh.ps1 install -DshHome "D:\你的\DSH数据目录"`

**Q：我自己在 cordis.patch.yml 里写了别的条目**
没问题 —— 本工具只管理自己标记的块（追加在文件末尾），你的条目原样保留。建议别把自己的条目写在破甲块后面（卸载按块边界移除）。

**Q：无窗口模式下怎么排错？**
看 `%USERPROFILE%\.dsh\logs\unlock-mode-launcher.log`，以及 `%TEMP%\dsh-unlock-result.txt`。

## 兼容性

| 部署形态 | preset 注册方式 | 支持 |
|---|---|---|
| DSH Desktop / Web / headless / tui，**0.2.0+**（含 0.2.0-rc.2） | 声明式（profile patch 层） | ✅ 本工具 |
| DSH ≤ 0.1.x（目录扫描式） | `$DSH_HOME\.agent-presets\` | ❌ 请用 [v1.1 release](https://github.com/z91772524-ai/dsh-pojia-mode/releases) |
| Windows 10 / 11 | — | ✅ |
| PowerShell 5.1（系统自带）/ 7+ | — | ✅ |

**为什么多 profile 通吃**：默认安装到 `profiles\` 下**所有**已存在的 profile（desktop / web / 自建都算），一个都没有时按 DSH Desktop 默认创建 `desktop`。也可以用 `-ProfileName` 只装某一个。

## 卸载 / 回滚

```powershell
.\unlock-dsh.ps1 uninstall
```

各 profile 的 `cordis.patch.yml` 里本工具的块会被整块移除（你的其他条目原样保留），0.1.x 遗留目录同步迁移。DSH 下次启动就不再列出该 preset，**其余一切不受影响**。反悔就再跑一次 `install`。

## 交流 & 支持

- **QQ 交流群：`1121243020`** —— 使用问题、更新通知、新版本都发在群里，有问题直接来问
- **Telegram 交流群：[t.me/shendusikao666](https://t.me/shendusikao666)** —— 墙外 / 海外的朋友走这边（群名「深度思考」）
- **GitHub Issues**：[提问题 / 反馈](https://github.com/z91772524-ai/dsh-pojia-mode/issues)

> 装完有问题，先跑一遍 `verify` 或 `diagnose` 并把输出贴上来，定位快很多。

## 免责声明

**本项目仅用于学习交流，无不良引导。**

本项目通过向 DeepSeek Harness 的用户 profile patch 层写入一份受管的 Agent Preset 声明，来改变该软件默认的助手行为。使用者应当：

1. 自行确认对目标软件与本机环境拥有合法处置权；
2. 遵守所在地法律法规以及目标软件的服务条款；
3. 自行承担使用本项目产生的一切后果。

**若他人使用本项目从事任何违法、违规或侵权行为，与作者没有任何关系，全部后果由使用者自行承担。**

## License

[MIT](LICENSE)
