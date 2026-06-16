param(
    [string]$ProjectDir = "."
)

$ErrorActionPreference = "Stop"

function Write-Check {
    param([string]$Name, [string]$Value)
    Write-Output ("{0}: {1}" -f $Name, $Value)
}

$resolved = Resolve-Path -LiteralPath $ProjectDir -ErrorAction Stop
Set-Location -LiteralPath $resolved
Write-Check "project_dir" (Get-Location).Path

$pythonPath = ""
if ($env:PYTHON) { $pythonPath = $env:PYTHON }
if (-not $pythonPath) {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) { $python = Get-Command py -ErrorAction SilentlyContinue }
    if ($python) { $pythonPath = $python.Source }
}
if (-not $pythonPath) {
    $bundled = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    if (Test-Path -LiteralPath $bundled) { $pythonPath = $bundled }
}
if ($pythonPath) {
    $version = & $pythonPath --version 2>&1
    if ($version) {
        Write-Check "python" $version
    } else {
        Write-Check "python" ("found {0}, version-unavailable" -f $pythonPath)
    }
} else {
    Write-Check "python" "missing"
}

$openclaw = Get-Command openclaw -ErrorAction SilentlyContinue
if ($openclaw) {
    $version = & $openclaw.Source --version 2>&1 | Select-Object -First 1
    Write-Check "openclaw" $version
} else {
    Write-Check "openclaw" "missing"
}

foreach ($path in @(".env", ".env.example", "real_bot.env.example", "pyproject.toml", "package.json")) {
    if (Test-Path -LiteralPath $path) {
        Write-Check $path "present"
    } else {
        Write-Check $path "missing"
    }
}

if ((Test-Path -LiteralPath "pyproject.toml") -and ((Get-Content -Raw -LiteralPath "pyproject.toml") -match "feishu-chatgpt-agent-shell")) {
    Write-Check "track" "feishu-chatgpt-agent-shell"
} elseif (Test-Path -LiteralPath "feishu-chatgpt-agent-shell") {
    Write-Check "track" "nested feishu-chatgpt-agent-shell"
} else {
    Write-Check "track" "custom-or-openclaw"
}

$appPort = ""
if (Test-Path -LiteralPath ".env") {
    $portLine = Get-Content -LiteralPath ".env" | Where-Object { $_ -match "^\s*APP_PORT\s*=" } | Select-Object -First 1
    if ($portLine) {
        $appPort = ($portLine -split "=", 2)[1].Trim().Trim('"').Trim("'")
    }
}
if (-not $appPort) { $appPort = "18080" }

$listener = Get-NetTCPConnection -LocalPort ([int]$appPort) -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($listener) {
    Write-Check "port_$appPort" "listening"
} else {
    Write-Check "port_$appPort" "not-listening"
}

$healthUrl = "http://127.0.0.1:$appPort/health"
try {
    $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 3
    Write-Check "health" ("ok {0} status={1}" -f $healthUrl, $response.StatusCode)
} catch {
    Write-Check "health" "unavailable $healthUrl"
}

$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    try {
        $gitRoot = & git rev-parse --show-toplevel 2>&1
        if ($LASTEXITCODE -eq 0 -and $gitRoot) {
            Write-Check "git_root" $gitRoot
            $status = & git status --porcelain 2>&1
            if ($LASTEXITCODE -eq 0) {
                if ($status) {
                    Write-Check "git_status" "dirty"
                } else {
                    Write-Check "git_status" "clean"
                }
            } else {
                Write-Check "git_status" ("unavailable " + (($status | Select-Object -First 1) -replace "\s+", " "))
            }
        } else {
            Write-Check "git" ("unavailable " + (($gitRoot | Select-Object -First 1) -replace "\s+", " "))
        }
    } catch {
        Write-Check "git" ("unavailable " + ($_.Exception.Message -replace "\s+", " "))
    }
}
