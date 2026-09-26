# 默认精选包与原始总库的差异

默认精选包保留当前版本 API、环境指纹、模板、工具和人类浏览 HTML 报告；玩家运行日志、精选源码、旧版 `legacy/` 和完整已安装模组源码都已删除。HTML 只供人类浏览，不作为默认 AI 事实来源。

默认包新增的主要 AI 辅助文件包括：

- `AI_INGESTION_GUIDE.md`
- `ai_manifest.json`
- `ai_file_index.jsonl`
原包另外保留了 `AI_TOTAL_LIBRARY_MANIFEST.json` 和 `AI_TOTAL_LIBRARY_INDEX.jsonl`，避免把精选包索引误当成原包索引。源码快照及其清单已经删除。玩家日志不纳入任何包；需要排错时使用当前玩家单独提供的日志。
