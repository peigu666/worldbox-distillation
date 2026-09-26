# WorldBox 第三方 API 提取器

这是独立于任何知识包的版本档案生成工具。它读取指定的 WorldBox 安装目录，将 Managed DLL 和 NeoModLoader Assemblies 的类型、方法、字段、属性、事件以及程序集哈希写入指定输出目录。

示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\extract-assembly-api.ps1 `
  -WorldBoxRoot "E:\Games\WorldBox" `
  -OutputRoot "E:\WorldBoxApiProfiles\0.51.3"
```

输出目录会生成：

- `api/third_party_api.types.jsonl`
- `api/third_party_api.manifest.json`

每个版本应使用独立的输出目录。提取完成后，使用对应知识包的 `verify-worldbox-pack.ps1` 校验核心程序集；不要把不同版本的 JSONL 混合到同一个 API 档案中。
