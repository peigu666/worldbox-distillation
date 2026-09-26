[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorldBoxRoot,

    [Parameter(Mandatory = $true)]
    [string]$OutputRoot,

    [string[]]$AssemblyPath,

    [switch]$IncludeCore
)

$ErrorActionPreference = 'Stop'
trap {
    Write-Error ("Extractor failed at line {0}: {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
    break
}
$worldBoxRoot = [IO.Path]::GetFullPath($WorldBoxRoot)
$outputRoot = [IO.Path]::GetFullPath($OutputRoot)
$cecilPath = Join-Path $PSScriptRoot 'parser_runtime\Mono.Cecil.dll'
if (-not (Test-Path -LiteralPath $cecilPath -PathType Leaf)) {
    throw "Mono.Cecil.dll not found: $cecilPath"
}
Add-Type -Path $cecilPath

function Convert-TypeName([object]$TypeReference) {
    if ($null -eq $TypeReference) { return $null }
    return $TypeReference.FullName.Replace('/', '+')
}

function Convert-Parameter([object]$Parameter) {
    return [pscustomobject][ordered]@{
        name = $Parameter.Name
        index = $Parameter.Index
        parameter_type = Convert-TypeName $Parameter.ParameterType
        attributes = $Parameter.Attributes.ToString()
        is_in = $Parameter.IsIn
        is_out = $Parameter.IsOut
        is_optional = $Parameter.IsOptional
        has_constant = $Parameter.HasConstant
    }
}

function Convert-TypeDefinition([object]$Type, [string]$AssemblyRole) {
    if ($Type.Name -eq '<Module>') { return $null }
    $methods = @($Type.Methods | ForEach-Object {
        [pscustomobject][ordered]@{
            name = $_.Name
            full_name = $_.FullName
            return_type = Convert-TypeName $_.ReturnType
            is_public = $_.IsPublic
            is_private = $_.IsPrivate
            is_static = $_.IsStatic
            is_abstract = $_.IsAbstract
            is_virtual = $_.IsVirtual
            is_constructor = $_.IsConstructor
            is_special_name = $_.IsSpecialName
            parameters = @($_.Parameters | ForEach-Object { Convert-Parameter $_ })
        }
    })
    $fields = @($Type.Fields | ForEach-Object {
        [pscustomobject][ordered]@{
            name = $_.Name
            full_name = $_.FullName
            field_type = Convert-TypeName $_.FieldType
            is_public = $_.IsPublic
            is_private = $_.IsPrivate
            is_static = $_.IsStatic
            is_literal = $_.IsLiteral
            is_init_only = $_.IsInitOnly
        }
    })
    $properties = @($Type.Properties | ForEach-Object {
        [pscustomobject][ordered]@{
            name = $_.Name
            full_name = $_.FullName
            property_type = Convert-TypeName $_.PropertyType
            parameters = @($_.Parameters | ForEach-Object { Convert-Parameter $_ })
            has_get = ($null -ne $_.GetMethod)
            has_set = ($null -ne $_.SetMethod)
        }
    })
    $events = @($Type.Events | ForEach-Object {
        [pscustomobject][ordered]@{
            name = $_.Name
            full_name = $_.FullName
            event_type = Convert-TypeName $_.EventType
        }
    })
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        assembly_role = $AssemblyRole
        full_name = $Type.FullName.Replace('/', '+')
        namespace = $Type.Namespace
        name = $Type.Name
        base_type = Convert-TypeName $Type.BaseType
        interfaces = @($Type.Interfaces | ForEach-Object { Convert-TypeName $_.InterfaceType })
        is_public = $Type.IsPublic
        is_nested = $Type.IsNested
        is_abstract = $Type.IsAbstract
        is_sealed = $Type.IsSealed
        is_interface = $Type.IsInterface
        is_value_type = $Type.IsValueType
        is_enum = $Type.IsEnum
        methods = $methods
        fields = $fields
        properties = $properties
        events = $events
        enum_values = if ($Type.IsEnum) { @($Type.Fields | Where-Object { $_.IsLiteral } | ForEach-Object { $_.Name }) } else { @() }
    }
}

function Get-NestedTypes([object]$Type) {
    $items = New-Object System.Collections.Generic.List[object]
    $items.Add($Type)
    foreach ($nested in $Type.NestedTypes) {
        foreach ($item in Get-NestedTypes $nested) { $items.Add($item) }
    }
    return $items
}

if ($AssemblyPath) {
    $paths = @($AssemblyPath | ForEach-Object { [IO.Path]::GetFullPath($_) })
} else {
    $paths = @()
    $paths += Get-ChildItem -File -Filter '*.dll' -LiteralPath (Join-Path $worldBoxRoot 'worldbox_Data\Managed') | ForEach-Object { $_.FullName }
    $paths += Get-ChildItem -File -Filter '*.dll' -LiteralPath (Join-Path $worldBoxRoot 'worldbox_Data\StreamingAssets\mods\NML\Assemblies') -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
}
$coreNames = @('Assembly-CSharp.dll', 'NeoModLoader.dll', '0Harmony.dll', 'Assembly-CSharp-Publicized.dll')
if (-not $IncludeCore) {
    $paths = @($paths | Where-Object { $coreNames -notcontains ([IO.Path]::GetFileName($_)) })
}
if ($paths.Count -eq 0) { throw 'No assemblies selected.' }

$apiDir = Join-Path $outputRoot 'api'
New-Item -ItemType Directory -Force -Path $apiDir | Out-Null
$jsonlPath = Join-Path $apiDir 'third_party_api.types.jsonl'
$manifestPath = Join-Path $apiDir 'third_party_api.manifest.json'
$writer = New-Object IO.StreamWriter($jsonlPath, $false, (New-Object Text.UTF8Encoding($false)))
$summaries = New-Object System.Collections.Generic.List[object]
try {
    foreach ($path in $paths | Sort-Object) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
        $file = Get-Item -LiteralPath $path
        $portable = $path
        if ($path.StartsWith($worldBoxRoot, [StringComparison]::OrdinalIgnoreCase)) {
            $portable = $path.Substring($worldBoxRoot.Length).TrimStart('\').Replace('\', '/')
        }
        $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($path)
        $role = 'third_party'
        $typeCount = 0
        foreach ($top in $assembly.MainModule.Types) {
            foreach ($type in Get-NestedTypes $top) {
                $record = Convert-TypeDefinition $type $role
                if ($null -ne $record) {
                    $writer.WriteLine(($record | ConvertTo-Json -Depth 50 -Compress))
                    $typeCount++
                }
            }
        }
        $summaries.Add([pscustomobject][ordered]@{
            schema_version = '1.0'
            role = $role
            module_name = $assembly.MainModule.Name
            portable_path = $portable
            sha256 = $hash
            size = $file.Length
            assembly_full_name = $assembly.Name.FullName
            assembly_version = $assembly.Name.Version.ToString()
            mvid = $assembly.MainModule.Mvid.ToString()
            type_count = $typeCount
            api_jsonl = 'api/third_party_api.types.jsonl'
        })
        # Mono.Cecil assemblies are released with the process; Dispose() is not
        # available on every supported Cecil build.
    }
} finally {
    $writer.Dispose()
}
$typeTotal = 0
foreach ($summary in $summaries) { $typeTotal += [int]$summary.type_count }
$summaryArray = New-Object object[] $summaries.Count
if ($summaries.Count -gt 0) { $summaries.CopyTo($summaryArray, 0) }
$manifest = [pscustomobject][ordered]@{
    schema_version = '1.0'
    generated_by = 'worldbox-api-extractor/1.0.0'
    generated_at_utc = [DateTime]::UtcNow.ToString('o')
    worldbox_root_at_generation = $worldBoxRoot
    role = 'third_party'
    assembly_count = $summaries.Count
    type_count = $typeTotal
    assemblies = $summaryArray
}
$manifest | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 -LiteralPath $manifestPath
Write-Output "Wrote $($summaries.Count) assemblies and $($manifest.type_count) types."
