# WorldBox AI 清理知识包

这是从原始知识包生成的 AI 默认读取版，严格对应 WorldBox 0.51.2（build 719）、Unity 2022.3.60f1、NeoModLoader 1.2.0.1、Harmony 2.9.0.0；不把它泛化为全部 0.51.x 版本。

## 推荐读取顺序

1. 先读 `ai_manifest.json` 和本文件。
2. 先查 `environment/`，确认版本、SHA-256 和 MVID。
3. API 查询优先使用 `api/*.types.jsonl`：
   - `raw_game_api.types.jsonl`：原始访问权限、IL 和运行时实现证据；
   - `publicized_compile_api.types.jsonl`：普通模组编译面；
   - `neomodloader_api.types.jsonl`：NeoModLoader 1.2.0.1；
   - `harmony_api.types.jsonl`：当前 Harmony。
4. 需要构建模板时读 `templates/`。
5. 排查运行问题时，必须读取当前用户实际环境中的 `Player.log`、错误日志（通常是 `logs/error_*.log`）以及用户指定的相关模组源码和项目文件。

不要把 raw API 和 Publicized API 合并，也不要根据旧资料或方法名猜参数签名。若本机存在当前 DLL，应以 DLL、编译结果、当前用户日志和相关模组源码为最终依据。`Player.log`、错误日志和模组源码的路径因用户而异，必须使用用户提供的路径或先定位实际 WorldBox/Mods 目录，不能写死 `D:\worldbox`、用户目录或包生成时的绝对路径。

## 工具

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\query-complete-api.ps1 -PackRoot $PWD -AssemblyRole worldbox_raw -TypeName Actor -Member hasTrait
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-worldbox-pack.ps1 -WorldBoxRoot "<用户实际的WorldBox目录>" -PackRoot $PWD -VerifyPdb -VerifyPackFiles
```

## 边界

- 这是当前 API、模板、工具和人类浏览 HTML 报告的默认包；旧 `legacy/` 已删除。
- 全部已安装模组源码及其来源清单未随包分发；需要分析具体模组时，只读取用户指定的相关源码、`.csproj`、`mod.json` 和构建输出。
- 玩家运行日志不随包分发；需要排错时必须单独读取当前用户的 `Player.log`、`logs/error_*.log` 及其他相关日志。
- 模板编译依赖用户本机的 WorldBox 和 NeoModLoader 安装，通过 `WorldBoxDir` 指向游戏根目录。
- `worldbox_ai_knowledge_report.html` 供人类浏览，不是默认 AI 事实来源。
- 图片、音频、DLL、PDB、存档和游戏数据库不在默认包内。
- `Locales/*.json` 按源文本处理；部分文件有注释、尾逗号或大小写重复键，不能要求严格 JSON 解析。
- `path_at_generation` 和源码项目中的绝对路径只用于审计；使用 `portable_path`、`WorldBoxDir` 和哈希。日志、Mods 和源码路径也必须视为用户可变路径。

## 资料优先级

当前 API JSONL > 当前 DLL/编译验证 > 当前用户的 Player.log/错误日志 > 用户指定的相关模组源码和构建结果 > 模板和工具 > HTML 人类报告。
