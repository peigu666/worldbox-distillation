# Unity 与第三方程序集 API

`api/third_party_api.types.jsonl` 是从当前 WorldBox 安装的 Managed DLL 和 NML Assemblies 生成的完整类型成员索引。它记录类型、继承、接口、方法参数/返回值、字段、属性、事件、程序集版本、SHA-256 和 MVID；不伪造 IL 或跨版本签名。

查询示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\query-complete-api.ps1 `
  -PackRoot $PWD -AssemblyRole third_party -TypeName UnityEngine.GameObject
```

提取器是独立工具，不属于本知识包。为其他 WorldBox 版本重新生成档案：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<提取器目录>\extract-assembly-api.ps1" `
  -WorldBoxRoot "E:\Games\WorldBox" -OutputRoot "E:\WorldBoxApiProfiles\0.51.3"
```

生成后必须重新运行 `verify-worldbox-pack.ps1`。不同游戏 DLL、Unity 版本或加载器版本应生成新的 API 档案，不能混用旧 JSONL。
