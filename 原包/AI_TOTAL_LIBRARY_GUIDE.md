# WorldBox AI 总库使用说明

这个目录是原包资料库；同级的 `../精选包/` 是可以直接喂给 AI 的默认精选包。资料严格对应 WorldBox 0.51.2（build 719）、Unity 2022.3.60f1、NeoModLoader 1.2.0.1、Harmony 2.9.0.0，不应直接外推到其他 0.51.x 版本。

## 推荐读取顺序

1. 先读本文件和 `AI_TOTAL_LIBRARY_MANIFEST.json`。
2. 默认开发、API 查询和排错，优先读同级的 `../精选包/`。
3. `worldbox_ai_knowledge_report.html` 只用于人类浏览，不是 AI 的主要 API 来源。
4. 旧版 `legacy/`、精选源码和全量已安装模组源码未随库分发；需要具体模组上下文时读取用户指定的少量模组源码。

## 目录角色

- `../精选包/`：默认精选包，包含自己的指南、版本清单、HTML 和文件哈希索引。
- `AI_NOTES/`：本总库的备注和差异说明。
- `api/`、`environment/`、`templates/`、`tools/`：原始总库的当前规范资料。
- 玩家运行日志不随资料库分发；排查时必须使用当前用户实际路径中的 `Player.log`、`logs/error_*.log` 和其他相关日志。
- 旧版 `legacy/` 已按要求删除。

## 重要规则

- Raw API、Publicized API、NeoModLoader API 和 Harmony API 不要混合推断。
- 当前用户 WorldBox 目录中的 DLL、编译结果、`Player.log`、错误日志和用户指定的相关模组源码优先级最高；不要假设游戏一定安装在 `D:\worldbox`。
- 模组源码、`.csproj`、`mod.json` 和构建输出的实际路径因用户而异，应由用户提供或从实际 WorldBox/Mods 目录定位。
- `AI_TOTAL_LIBRARY_INDEX.jsonl` 是原包级文件索引；`../精选包/ai_file_index.jsonl` 是精选包级索引。
