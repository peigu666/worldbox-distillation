# 模组模板

默认使用 `net48` 模板；先把 `WorldBoxDir` 指向游戏根目录，再编译：

```powershell
dotnet build .\WorldBoxMod.net48.csproj /p:WorldBoxDir="E:\Games\WorldBox"
```

`net48.raw.csproj` 用于需要核对原始访问权限的场景。`net6.csproj` 和
`netstandard2.1.csproj` 仍可使用，但在当前 NeoModLoader 发行包上可能出现
框架程序集版本冲突警告，不作为默认模板。

本知识包不包含可用于编译的 WorldBox 或 NeoModLoader 游戏程序集；`WorldBoxDir` 必须指向用户本机的完整游戏目录，并且其中应有与清单哈希匹配的 NeoModLoader 1.2.0.1。`environment/loader_reference_manifest.json` 仅记录来源和指纹，不是可直接引用的二进制文件。

模板默认引用 `Assembly-CSharp-Publicized.dll`，适合普通模组开发；`WorldBoxMod.net48.raw.csproj` 专门用于需要核对原始访问权限的场景。模板中的 `MinimalWorldBoxMod.cs` 和 `mod.json` 会随构建复制到输出目录。
