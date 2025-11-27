param([switch]$rebuild = $false, [switch]$fresh = $false, [int]$port = 8000, [switch]$help = $false)

function Log { param([string]$m, [string]$t = "info"); $c = @{"success" = "Green"; "error" = "Red"; "warning" = "Yellow"; "info" = "Cyan"; "header" = "Magenta" }; Write-Host $m -ForegroundColor $c[$t] }

if ($help) {
    Write-Host "FastAPI Backend Startup Script`n`nUsage: .\start-app.ps1 [-rebuild] [-fresh] [-port 8001] [-help]`n`nOptions:`n  -rebuild   Rebuild venv and reinstall requirements`n  -fresh     Delete and recreate venv`n  -port      Custom port (default 8000)`n  -help      Show this help"
    exit 0
}

$sd = Split-Path -Parent $MyInvocation.MyCommand.Path
$bd = Join-Path $sd "backend"
$vp = Join-Path $bd "venv"
$pe = Join-Path $vp "Scripts\python.exe"
$pi = Join-Path $vp "Scripts\pip.exe"
$rf = Join-Path $bd "requirements.txt"
$mf = Join-Path $bd "main.py"

Log "=====================================================================" "header"
Log "           NovaDraw FastAPI Backend Startup Script" "header"
Log "=====================================================================" "header"
Log ""

Log "[1/4] Checking Python Virtual Environment..." "info"

if ($fresh -and (Test-Path $vp)) {
    Log "  -> Deleting existing venv..." "warning"
    Remove-Item -Recurse -Force $vp
    Log "  [OK] Venv deleted" "success"
}

if (-not(Test-Path $vp)) {
    Log "  -> Creating new venv..." "warning"
    python -m venv $vp
    if ($LASTEXITCODE -ne 0) { Log "  [ERROR] Failed to create venv" "error"; exit 1 }
    Log "  [OK] Venv created" "success"
    $rebuild = $true
}
else {
    Log "  [OK] Venv exists" "success"
}

Log "[2/4] Activating Virtual Environment..." "info"

$as = Join-Path $vp "Scripts\Activate.ps1"
if (-not(Test-Path $as)) { Log "  [ERROR] Activation script not found" "error"; exit 1 }

& $as
Log "  [OK] Venv activated" "success"

Log "[3/4] Managing Dependencies..." "info"

if ($rebuild) {
    Log "  -> Reinstalling requirements..." "warning"
    if (-not(Test-Path $rf)) { Log "  [ERROR] requirements.txt not found" "error"; exit 1 }
    Log "  -> Upgrading pip..." "info"
    & $pe -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) { Log "  [ERROR] Failed to upgrade pip" "error"; exit 1 }
    Log "  -> Installing requirements..." "info"
    & $pi install -r $rf
    if ($LASTEXITCODE -ne 0) { Log "  [ERROR] Failed to install requirements" "error"; exit 1 }
    Log "  [OK] Requirements installed" "success"
}
else {
    Log "  -> Checking packages..." "info"
    $pl = & $pi list --format=json | ConvertFrom-Json
    if ($pl.Count -lt 5) {
        Log "  -> Installing requirements..." "warning"
        & $pi install -r $rf
        if ($LASTEXITCODE -ne 0) { Log "  [ERROR] Failed to install requirements" "error"; exit 1 }
        Log "  [OK] Requirements installed" "success"
    }
    else {
        Log "  [OK] Requirements already installed" "success"
    }
}

Log "[4/4] Starting FastAPI Application..." "info"
Log ""

if (-not(Test-Path $mf)) { Log "  [ERROR] main.py not found" "error"; exit 1 }

Log "=====================================================================" "header"
Log "                    Server Configuration" "header"
Log "=====================================================================" "header"
Log "  Host:          127.0.0.1" "info"
Log "  Port:          $port" "info"
Log "  App:           main:app" "info"
Log "  Reload:        Enabled" "info"
Log ""
Log "  API URL: http://127.0.0.1:$port" "success"
Log "  Docs:    http://127.0.0.1:$port/docs" "success"
Log ""
Log "Press Ctrl+C to stop the server" "warning"
Log ""

Push-Location $bd
& $pe -m uvicorn main:app --host 127.0.0.1 --port $port --reload --log-level info
Pop-Location

Log ""
Log "Application stopped" "warning"
exit 0
