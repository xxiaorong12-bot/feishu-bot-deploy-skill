param(
    [string]$ProjectDir = ".",
    [string]$EnvFile = "",
    [int]$TimeoutSec = 12,
    [switch]$SkipNetwork
)

$ErrorActionPreference = "Stop"

function Write-Item {
    param([string]$Name, [string]$Value)
    Write-Output ("{0}: {1}" -f $Name, $Value)
}

function Mask-Value {
    param([string]$Value)
    if (-not $Value) { return "missing" }
    if ($Value.Length -le 8) { return "set" }
    return ($Value.Substring(0, 4) + "***" + $Value.Substring($Value.Length - 4))
}

function Test-Placeholder {
    param([string]$Value)
    if (-not $Value) { return $true }
    return ($Value -match "(?i)xxx|your-|example|\.\.\.|test|local_verify|1234|placeholder")
}

function Import-EnvFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Item "env_file" "missing $Path"
        return
    }
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith("#")) { continue }
        $parts = $trimmed -split "=", 2
        if ($parts.Count -ne 2) { continue }
        $name = $parts[0].Trim()
        $value = $parts[1].Trim().Trim('"').Trim("'")
        if ($name -match "^[A-Za-z_][A-Za-z0-9_]*$") {
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
    Write-Item "env_file" "loaded $Path"
}

function Set-EnvDefault {
    param([string]$Name, [string]$Value)
    if (-not [Environment]::GetEnvironmentVariable($Name, "Process")) {
        [Environment]::SetEnvironmentVariable($Name, $Value, "Process")
    }
}

function Normalize-BaseUrl {
    param([string]$Value)
    if (-not $Value) { return "" }
    return $Value.Trim().TrimEnd("/")
}

function Normalize-Path {
    param([string]$Value, [string]$Default)
    if (-not $Value) { $Value = $Default }
    if (-not $Value.StartsWith("/")) { return "/" + $Value }
    return $Value
}

function Test-LocalPortListening {
    param([int]$Port)
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $async = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
        $ok = $async.AsyncWaitHandle.WaitOne(1000, $false)
        return ($ok -and $client.Connected)
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function Invoke-Health {
    param([string]$Url)
    try {
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSec
        Write-Item "health_probe" ("ok {0} {1}" -f $resp.StatusCode, $Url)
        return $true
    } catch {
        Write-Item "health_probe" ("failed {0}" -f $_.Exception.Message)
        return $false
    }
}

function Invoke-FeishuTokenProbe {
    param([string]$ApiBase, [string]$AppId, [string]$AppSecret)
    $url = $ApiBase.TrimEnd("/") + "/auth/v3/tenant_access_token/internal"
    $body = @{ app_id = $AppId; app_secret = $AppSecret } | ConvertTo-Json -Compress
    try {
        $resp = Invoke-RestMethod -Method Post -Uri $url -Body $body -ContentType "application/json; charset=utf-8" -TimeoutSec $TimeoutSec
        if ($resp.code -eq 0 -and $resp.tenant_access_token) {
            Write-Item "tenant_token_probe" "ok"
            return $true
        }
        Write-Item "tenant_token_probe" ("failed code={0} msg={1}" -f $resp.code, $resp.msg)
        return $false
    } catch {
        Write-Item "tenant_token_probe" ("failed {0}" -f $_.Exception.Message)
        return $false
    }
}

$projectPath = Resolve-Path -LiteralPath $ProjectDir
if (-not $EnvFile) { $EnvFile = Join-Path $projectPath ".env" }
Import-EnvFile -Path $EnvFile

Set-EnvDefault "APP_HOST" "127.0.0.1"
Set-EnvDefault "APP_PORT" "18080"
Set-EnvDefault "HEALTH_PATH" "/health"
Set-EnvDefault "FEISHU_CALLBACK_PATH" "/lark/events"
Set-EnvDefault "FEISHU_API_BASE" "https://open.feishu.cn/open-apis"

$port = [int][Environment]::GetEnvironmentVariable("APP_PORT", "Process")
$healthPath = Normalize-Path ([Environment]::GetEnvironmentVariable("HEALTH_PATH", "Process")) "/health"
$callbackPath = Normalize-Path ([Environment]::GetEnvironmentVariable("FEISHU_CALLBACK_PATH", "Process")) "/lark/events"
$publicBase = Normalize-BaseUrl ([Environment]::GetEnvironmentVariable("PUBLIC_BASE_URL", "Process"))
$apiBase = [Environment]::GetEnvironmentVariable("FEISHU_API_BASE", "Process")

Write-Item "project" $projectPath
Write-Item "app_id" (Mask-Value $env:FEISHU_APP_ID)
Write-Item "app_secret" (Mask-Value $env:FEISHU_APP_SECRET)
Write-Item "verification_token" (Mask-Value $env:FEISHU_VERIFICATION_TOKEN)
Write-Item "encrypt_key" (Mask-Value $env:FEISHU_ENCRYPT_KEY)
Write-Item "local_health" ("http://127.0.0.1:{0}{1}" -f $port, $healthPath)
Write-Item "local_callback" ("http://127.0.0.1:{0}{1}" -f $port, $callbackPath)
if ($publicBase) {
    Write-Item "public_health" ($publicBase + $healthPath)
    Write-Item "public_callback" ($publicBase + $callbackPath)
} else {
    Write-Item "public_base_url" "missing"
}

$missing = @()
foreach ($name in @("FEISHU_APP_ID", "FEISHU_APP_SECRET", "FEISHU_VERIFICATION_TOKEN")) {
    if (-not [Environment]::GetEnvironmentVariable($name, "Process")) { $missing += $name }
}
if (-not $publicBase) { $missing += "PUBLIC_BASE_URL" }

$placeholders = @()
foreach ($name in @("FEISHU_APP_ID", "FEISHU_APP_SECRET", "FEISHU_VERIFICATION_TOKEN")) {
    $value = [Environment]::GetEnvironmentVariable($name, "Process")
    if (Test-Placeholder $value) { $placeholders += $name }
}

if ($missing.Count -gt 0) {
    Write-Item "ready_env" ("missing " + ($missing -join ", "))
} elseif ($placeholders.Count -gt 0) {
    Write-Item "ready_env" ("placeholder " + ($placeholders -join ", "))
} else {
    Write-Item "ready_env" "ok"
}

if (Test-LocalPortListening $port) {
    Write-Item "port_$port" "listening"
} else {
    Write-Item "port_$port" "not-listening"
}

if ($SkipNetwork) {
    Write-Item "network_probes" "skipped"
    if ($missing.Count -gt 0 -or $placeholders.Count -gt 0) { exit 2 }
    exit 0
}

$networkFailures = 0
if (-not (Invoke-Health ("http://127.0.0.1:{0}{1}" -f $port, $healthPath))) { $networkFailures += 1 }
if ($publicBase -and (-not (Invoke-Health ($publicBase + $healthPath)))) { $networkFailures += 1 }

if (($missing.Count -eq 0) -and ($placeholders.Count -eq 0)) {
    if (-not (Invoke-FeishuTokenProbe $apiBase $env:FEISHU_APP_ID $env:FEISHU_APP_SECRET)) { $networkFailures += 1 }
} else {
    Write-Item "tenant_token_probe" "skipped until real app credentials are set"
}

if ($missing.Count -gt 0 -or $placeholders.Count -gt 0) { exit 2 }
if ($networkFailures -gt 0) { exit 3 }
exit 0
