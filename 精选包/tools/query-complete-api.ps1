[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PackRoot,

    [ValidateSet('worldbox_raw', 'worldbox_publicized', 'neomodloader', 'harmony', 'third_party')]
    [string]$AssemblyRole = 'worldbox_raw',

    [Parameter(Mandatory = $true)]
    [string]$TypeName,

    [string]$Member,

    [switch]$IncludeBody
)

$ErrorActionPreference = 'Stop'
$packRoot = [IO.Path]::GetFullPath($PackRoot)
$fileByRole = @{
    worldbox_raw        = 'raw_game_api.types.jsonl'
    worldbox_publicized = 'publicized_compile_api.types.jsonl'
    neomodloader        = 'neomodloader_api.types.jsonl'
    harmony             = 'harmony_api.types.jsonl'
    third_party         = 'third_party_api.types.jsonl'
}
$jsonl = Join-Path $packRoot ('api\' + $fileByRole[$AssemblyRole])
if (-not (Test-Path -LiteralPath $jsonl -PathType Leaf)) {
    throw "API JSONL not found: $jsonl"
}

$results = New-Object System.Collections.Generic.List[object]
foreach ($line in Get-Content -LiteralPath $jsonl -Encoding UTF8) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $record = $line | ConvertFrom-Json
    $typeMatches = ($record.full_name -eq $TypeName) -or ($record.name -eq $TypeName) -or ($record.full_name -like $TypeName)
    if (-not $typeMatches) { continue }

    if ([string]::IsNullOrWhiteSpace($Member)) {
        if ($IncludeBody) {
            $results.Add($record)
            continue
        }

        $results.Add([pscustomobject][ordered]@{
            assembly_role = $record.assembly_role
            full_name = $record.full_name
            base_type = $record.base_type
            interfaces = @($record.interfaces)
            is_enum = $record.is_enum
            methods = @($record.methods | ForEach-Object {
                [pscustomobject][ordered]@{
                    name = $_.name
                    full_name = $_.full_name
                    return_type = $_.return_type
                    is_public = $_.is_public
                    is_static = $_.is_static
                    parameters = @($_.parameters | ForEach-Object { $_.parameter_type + ' ' + $_.name })
                    il_hash = $_.il_hash
                }
            })
            fields = @($record.fields | ForEach-Object {
                [pscustomobject][ordered]@{
                    name = $_.name
                    field_type = $_.field_type
                    is_public = $_.is_public
                    is_static = $_.is_static
                    is_literal = $_.is_literal
                }
            })
            properties = @($record.properties)
            events = @($record.events)
            enum_values = @($record.enum_values)
        })
        continue
    }

    $methodMatches = @($record.methods | Where-Object { $_.name -like $Member -or $_.full_name -like $Member })
    $fieldMatches = @($record.fields | Where-Object { $_.name -like $Member })
    $propertyMatches = @($record.properties | Where-Object { $_.name -like $Member })
    $eventMatches = @($record.events | Where-Object { $_.name -like $Member })
    if (($methodMatches.Count + $fieldMatches.Count + $propertyMatches.Count + $eventMatches.Count) -gt 0) {
        $results.Add([pscustomobject][ordered]@{
            assembly_role = $record.assembly_role
            full_name = $record.full_name
            methods = if ($IncludeBody) { $methodMatches } else { @($methodMatches | Select-Object name, full_name, return_type, is_public, is_static, parameters, il_hash) }
            fields = $fieldMatches
            properties = $propertyMatches
            events = $eventMatches
        })
    }
}

if ($results.Count -eq 0) {
    throw "No match. AssemblyRole=$AssemblyRole TypeName=$TypeName Member=$Member"
}

$results | ConvertTo-Json -Depth 100
