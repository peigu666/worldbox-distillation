[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorldBoxRoot,

    [Parameter(Mandatory = $true)]
    [string]$PackRoot,

    [switch]$VerifyPdb,

    [switch]$VerifyPackFiles
)

$ErrorActionPreference = 'Stop'
$worldBoxRoot = [IO.Path]::GetFullPath($WorldBoxRoot)
$packRoot = [IO.Path]::GetFullPath($PackRoot)
$manifestPath = Join-Path $packRoot 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Pack manifest not found: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$failures = New-Object System.Collections.Generic.List[string]
$cecilPath = Join-Path $worldBoxRoot 'worldbox_Data\StreamingAssets\mods\NML\Assemblies\Mono.Cecil.dll'
$packCecilPath = Join-Path $packRoot 'tools\parser_runtime\Mono.Cecil.dll'
if (-not (Test-Path -LiteralPath $cecilPath -PathType Leaf) -and (Test-Path -LiteralPath $packCecilPath -PathType Leaf)) {
    $cecilPath = $packCecilPath
}
$canReadMvid = $false
if (Test-Path -LiteralPath $cecilPath -PathType Leaf) {
    try {
        Add-Type -Path $cecilPath -ErrorAction Stop
        $canReadMvid = $true
    } catch {
        $canReadMvid = $false
        Write-Warning "Mono.Cecil could not be loaded; SHA-256 will still be checked, MVID will be reported as unverified."
    }
}

foreach ($assembly in @($manifest.assemblies)) {
    $portable = [string]$assembly.portable_path
    $relative = $portable -replace '/', [IO.Path]::DirectorySeparatorChar
    $actualPath = Join-Path $worldBoxRoot $relative
    if (-not (Test-Path -LiteralPath $actualPath -PathType Leaf)) {
        $failures.Add("$($assembly.role): missing $actualPath")
        Write-Host "FAIL $($assembly.role): missing $actualPath" -ForegroundColor Red
        continue
    }

    $actualFile = Get-Item -LiteralPath $actualPath
    $actualHash = (Get-FileHash -LiteralPath $actualPath -Algorithm SHA256).Hash.ToUpperInvariant()
    $expectedHash = ([string]$assembly.file.sha256).ToUpperInvariant()
    $sizeOk = ([int64]$actualFile.Length -eq [int64]$assembly.file.size)
    $hashOk = ($actualHash -eq $expectedHash)
    $mvidText = 'not checked'
    $mvidOk = $true
    if ($canReadMvid -and -not [string]::IsNullOrWhiteSpace([string]$assembly.mvid)) {
        $definition = $null
        try {
            $definition = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($actualPath)
            $actualMvid = $definition.MainModule.Mvid.ToString()
            $mvidText = $actualMvid
            $mvidOk = ($actualMvid -ieq [string]$assembly.mvid)
        } finally {
            if ($null -ne $definition) { $definition.Dispose() }
        }
    }

    if ($sizeOk -and $hashOk -and $mvidOk) {
        Write-Host "OK   $($assembly.role) size=$($actualFile.Length) sha256=$actualHash mvid=$mvidText" -ForegroundColor Green
    } else {
        $failures.Add("$($assembly.role): sizeOk=$sizeOk hashOk=$hashOk mvidOk=$mvidOk actual=$actualPath")
        Write-Host "FAIL $($assembly.role) sizeOk=$sizeOk hashOk=$hashOk mvidOk=$mvidOk" -ForegroundColor Red
    }

    if ($VerifyPdb -and $null -ne $assembly.pdb) {
        $pdbPortable = [string]$assembly.pdb.portable_path
        $pdbPath = Join-Path $worldBoxRoot ($pdbPortable -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $pdbPath -PathType Leaf)) {
            $failures.Add("$($assembly.role): missing PDB $pdbPath")
        } else {
            $pdbHash = (Get-FileHash -LiteralPath $pdbPath -Algorithm SHA256).Hash.ToUpperInvariant()
            if ($pdbHash -ne ([string]$assembly.pdb.sha256).ToUpperInvariant()) {
                $failures.Add("$($assembly.role): PDB SHA-256 mismatch $pdbPath")
            }
        }
    }
}

if ($VerifyPackFiles) {
    $indexCandidates = @('ai_file_index.jsonl', 'AI_TOTAL_LIBRARY_INDEX.jsonl')
    $indexPath = $null
    foreach ($candidate in $indexCandidates) {
        $candidatePath = Join-Path $packRoot $candidate
        if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
            $indexPath = $candidatePath
            break
        }
    }

    if ($null -eq $indexPath) {
        $failures.Add('pack file index missing: expected ai_file_index.jsonl or AI_TOTAL_LIBRARY_INDEX.jsonl')
        Write-Host 'FAIL pack file index missing.' -ForegroundColor Red
    } else {
        $packRootPrefix = $packRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
        $seen = @{}
        $checked = 0
        foreach ($line in Get-Content -LiteralPath $indexPath -Encoding UTF8) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            try {
                $entry = $line | ConvertFrom-Json
            } catch {
                $failures.Add("pack file index JSON parse failed: $($_.Exception.Message)")
                continue
            }

            $relative = [string]$entry.path
            if ([string]::IsNullOrWhiteSpace($relative)) {
                $failures.Add('pack file index entry has no path')
                continue
            }
            if ($seen.ContainsKey($relative)) {
                $failures.Add("pack file index duplicate path: $relative")
                continue
            }
            $seen[$relative] = $true

            $actualPath = Join-Path $packRoot ($relative -replace '/', [IO.Path]::DirectorySeparatorChar)
            $resolvedPath = [IO.Path]::GetFullPath($actualPath)
            if (-not $resolvedPath.StartsWith($packRootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                $failures.Add("pack file index path escapes pack root: $relative")
                continue
            }
            if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
                $failures.Add("pack file missing: $relative")
                continue
            }

            $actualFile = Get-Item -LiteralPath $resolvedPath
            $actualHash = (Get-FileHash -LiteralPath $resolvedPath -Algorithm SHA256).Hash.ToUpperInvariant()
            $sizeOk = ($actualFile.Length -eq [int64]$entry.size)
            $hashOk = ($actualHash -eq ([string]$entry.sha256).ToUpperInvariant())
            if (-not ($sizeOk -and $hashOk)) {
                $failures.Add("pack file mismatch: $relative sizeOk=$sizeOk hashOk=$hashOk")
            } else {
                $checked++
            }
        }
        Write-Host "Pack file verification checked $checked file(s) from $([IO.Path]::GetFileName($indexPath))."
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Verification failed ($($failures.Count) issue(s))." -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host 'Verification passed.' -ForegroundColor Green
exit 0
