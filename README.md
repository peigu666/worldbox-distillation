# 世界盒子蒸馏

面向 WorldBox 模组开发与 AI 辅助排错的版本化知识库。

当前公开发布版本：`v1.0.0`

本仓库把 WorldBox、NeoModLoader、Harmony 以及 Unity/第三方程序集中的可检索 API 信息整理成带有版本指纹的 JSON/JSONL 索引，配套查询脚本、完整性校验脚本和可编译的模组模板。它的目标不是替代游戏本体，而是让 AI 和模组作者能够在真实 DLL 签名、参数、继承关系和程序集版本的基础上工作，减少凭旧教程猜方法名、猜重载或误用其他 0.51.x 版本 API 的情况。

## 当前版本档案

当前包严格对应以下环境：

- WorldBox 0.51.2，build 719
- Unity 2022.3.60f1
- NeoModLoader 1.2.0.1
- Harmony 2.9.0.0
- 原始 `Assembly-CSharp.dll` SHA-256：`51D275F0168BE2F6CA26341AB292406714E694E0270EAFCB25B999D5DF6DD69F`

所有核心程序集和 187 项环境程序集清单都带有 SHA-256；当前版本档案不可直接套用到其他 0.51.x。其他版本应使用仓库根目录的 `third_party_api_extractor` 生成新的 API 输出，并单独保存为新的版本档案。

## 原包与精选包

| 项目 | 原包 | 精选包 |
|---|---|---|
| 主要用途 | 完整归档、审计、离线浏览 | 默认喂给 AI、按需查询 |
| API 内容 | 与精选包相同 | 与原包相同 |
| 游戏原始 API | 包含，含 IL 信息 | 包含，含 IL 信息 |
| Publicized 编译 API | 包含 | 包含 |
| NeoModLoader / Harmony API | 包含 | 包含 |
| Unity/第三方 API | 包含 183 个程序集、30,934 个类型 | 包含 183 个程序集、30,934 个类型 |
| 主要索引 | `AI_TOTAL_LIBRARY_INDEX.jsonl` | `ai_file_index.jsonl` |
| 使用说明 | `README.md`、`AI_TOTAL_LIBRARY_GUIDE.md`、`AI_NOTES/` | `AI_INGESTION_GUIDE.md` |
| 默认推荐 | 不建议一次性全部加载 | 推荐先读取，再按需查询 |
| 适合场景 | 完整资料备份、差异审计 | 日常模组编写、API 查询、排错 |
| 是否包含玩家模组源码 | 否 | 否 |
| 是否包含玩家日志/存档 | 否 | 否 |

两包的核心 API 数据保持一致；精选包只是把入口、索引和说明整理成更适合 AI 的默认读取顺序。

## 快速使用

建议 AI 先读取：

1. `精选包/AI_INGESTION_GUIDE.md`
2. `精选包/ai_manifest.json`
3. `精选包/environment/*.json`
4. 按任务查询 `精选包/api/*.types.jsonl`

查询 WorldBox 游戏 API：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\精选包\tools\query-complete-api.ps1 `
  -PackRoot .\精选包 -AssemblyRole worldbox_raw -TypeName Actor -Member hasTrait
```

查询 Unity 或第三方 API：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\精选包\tools\query-complete-api.ps1 `
  -PackRoot .\精选包 -AssemblyRole third_party -TypeName GameObject
```

校验本地 WorldBox 是否与当前档案匹配：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\精选包\tools\verify-worldbox-pack.ps1 `
  -WorldBoxRoot "D:\worldbox" -PackRoot .\精选包 -VerifyPdb -VerifyPackFiles
```

## 为其他版本生成第三方 API

`third_party_api_extractor` 是独立工具，不属于任一版本知识包。它自带 Mono.Cecil，只依赖你指定的游戏目录和输出目录：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\third_party_api_extractor\extract-assembly-api.ps1 `
  -WorldBoxRoot "E:\Games\WorldBox" `
  -OutputRoot "E:\WorldBoxApiProfiles\0.51.3"
```

输出包括：

- `api/third_party_api.types.jsonl`
- `api/third_party_api.manifest.json`

不同 WorldBox、Unity、NeoModLoader 或 Harmony 版本的 JSONL 不应混合使用。

## 知识库的边界

本仓库保存的是版本化 API 和开发辅助资料，不包含：

- 玩家安装的全部模组源码、编译产物和个人配置
- `Player.log`、错误日志、存档和自动存档
- 游戏资源包、图片、音频或完整游戏安装包

实际排错时，应把当前机器的日志、相关模组源码和项目文件作为更高优先级证据。

## 搜索标签

`WorldBox`, `WorldBox Mod`, `WorldBox 0.51.2`, `WorldBox build 719`, `NeoModLoader`, `NML 1.2.0.1`, `Harmony 2.9.0.0`, `Unity 2022.3.60f1`, `Assembly-CSharp`, `Assembly-CSharp-Publicized`, `Unity API`, `third-party DLL API`, `C# modding`, `C# game modding`, `Unity modding`, `Harmony patch`, `IL patching`, `Mono.Cecil`, `mod development`, `mod loader`, `game reverse engineering`, `API knowledge base`, `AI coding knowledge`, `AI mod development`, `WorldBox Chinese`, `WorldBox tools`, `WorldBox developer tools`, `publicized API`, `runtime verification`, `DLL hash`, `MVID`, `JSONL API index`, `versioned API profile`.

## 说明与归属

WorldBox、Unity、NeoModLoader、Harmony 及其他第三方程序集的名称和版权归各自权利人所有。本仓库主要提供索引、版本指纹、查询工具、校验工具和开发说明；使用者应遵守相关软件的许可、服务条款和适用法律。
