# WorldBox AI 完整知识包

## 这是什么

这是面向 WorldBox 0.51.2（build 719）、NeoModLoader 1.2.0.1 和 Harmony 2.9.0.0 模组开发的知识包。它不代表全部 0.51.x 版本。旧版蒸馏资料已经删除，当前资料按程序集、来源角色和指纹组织。

生成器版本：`worldbox-ai-knowledge-generator/1.0.0`  
生成时间（UTC）：`2026-09-26T11:02:50.9654788+00:00`  
游戏程序集 SHA-256：`51D275F0168BE2F6CA26341AB292406714E694E0270EAFCB25B999D5DF6DD69F`  
游戏程序集 MVID：`3aa7d3da-1573-446f-8db1-3cd80acc5c24`  
NeoModLoader SHA-256：`E05FFB01B1E29A07F1BDD94D7BDE2A00A536C8AC8703A63F51BBBA743E40F93D`  
NeoModLoader 版本：`1.2.0.1`  
解析器版本：见 `environment/parser_manifest.json`

## 人类浏览

双击 `worldbox_ai_knowledge_report.html` 可离线浏览版本指纹、程序集统计和完整 API 搜索；它内嵌搜索索引，不依赖生成机器的绝对路径。

## 路径可移植性

`path_at_generation`、`WorldBoxRootAtGeneration` 等原始路径仅用于审计，不是运行依赖。分享给别人时，对方可以把 WorldBox 放在任何目录。

可移植定位使用：

- `portable_path`：相对于游戏根目录或 NML 目录的逻辑路径。
- `role`：文件的语义角色，例如 `WorldBox.Managed.Assembly-CSharp`。
- `sha256`、`mvid`：确认是否为同一版本的实际内容。

编译模板使用 `$(WorldBoxDir)`，例如：

```powershell
dotnet build .\templates\WorldBoxMod.net48.csproj /p:WorldBoxDir="E:\Games\WorldBox"
```

先运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-worldbox-pack.ps1 -WorldBoxRoot "E:\Games\WorldBox" -PackRoot $PWD -VerifyPdb -VerifyPackFiles
```

## 资料选择规则

1. `api/*raw_game_api*`：从当前原始 `Assembly-CSharp.dll` 提取的完整签名、继承、接口、属性、事件、特性、枚举、常量和 IL。
2. `api/*publicized_compile_api*`：编译模组实际使用的 Publicized 程序集表面；不要与原始访问权限混用。
3. `api/neomodloader_api*`：NeoModLoader 1.2.0.1 的类型与方法签名。
4. `api/harmony_api*`：当前安装的 0Harmony 类型与方法签名。
5. 需要排查运行问题时，读取当前用户实际路径中的 `Player.log`、`logs/error_*.log` 以及用户指定的相关模组源码和项目文件；这些路径因用户而异，不能假设为生成时的路径。

## 给 AI 的使用顺序

先读取本文件和 `manifest.json`，再按任务查询对应的 `*.types.jsonl`；不要一次性加载所有程序集。遇到重载、Harmony Patch、访问权限或编译错误时，必须结合 JSONL 中的真实签名、当前机器的 DLL 校验结果、`Player.log`/错误日志和相关模组源码，不得只根据知识库猜测。

## 已知边界

- IL 能说明真实控制流和调用目标，但不会自动变成人类可读的源代码。
- 游戏资源、图片、存档、数据库没有整体复制；已安装模组源码没有整体随库分发，需要时按用户指定路径读取相关模组。
- 如果对方的 SHA-256 或 MVID 不匹配，应生成新的版本档案，不能把两套 API 合并。
            
