#!/usr/bin/env pwsh
# NovaDraw AI - Local Server Management Script (No Docker)
# Handles: environment setup, database migrations, and local server startup
# Version: 1.0

param(
    [Parameter(Position = 0)]
    [ValidateSet("start", "stop", "migrate", "reset", "status")]
    [string]$Command = "start"
)

function Show-Menu {
    Write-Host ""
    Write-Host "NovaDraw AI - Local Server Manager (No Docker)" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\start-server-local.ps1 [command]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor White
    Write-Host "  start     - Start local server (default)" -ForegroundColor Gray
    Write-Host "  stop      - Stop the running server" -ForegroundColor Gray
    Write-Host "  migrate   - Run database migrations" -ForegroundColor Gray
    Write-Host "  status    - Show server status" -ForegroundColor Gray
    Write-Host "  reset     - Reset database and remove virtual environment" -ForegroundColor Gray
    Write-Host ""
}

# Initialize environment variables from .env file
function Initialize-Environment {
    if (-not (Test-Path ".env")) {
        Write-Host ".env file not found!" -ForegroundColor Red
        Write-Host "Creating from .env.example..." -ForegroundColor Yellow
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Host "Created .env file. Please edit it with your configuration." -ForegroundColor Green
            Write-Host "Opening .env in editor..." -ForegroundColor Yellow
            notepad .env
        }
        else {
            Write-Host "ERROR: .env.example not found!" -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host "Loading environment variables..." -ForegroundColor Yellow
    foreach ($line in (Get-Content .env)) {
        if ($line -match '^\s*#') { continue }
        if ($line -match '^\s*$') { continue }
        if ($line -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim('"').Trim("'").Trim()
            if ($value) {
                [Environment]::SetEnvironmentVariable($key, $value)
            }
        }
    }
    Write-Host "Environment loaded" -ForegroundColor Green
}

function Test-Python {
    try {
        $version = python --version 2>&1
        Write-Host "Found Python: $version" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Python is not installed or not in PATH. Please install Python 3.9+" -ForegroundColor Red
        return $false
    }
}

function Setup-VirtualEnvironment {
    Write-Host ""
    Write-Host "Setting up Python virtual environment..." -ForegroundColor Yellow
    
    # Check if venv exists
    if (-not (Test-Path "backend/venv")) {
        Write-Host "  Creating virtual environment..." -ForegroundColor Gray
        python -m venv backend/venv
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ✗ Failed to create virtual environment" -ForegroundColor Red
            exit 1
        }
        Write-Host "  ✓ Virtual environment created" -ForegroundColor Green
    }
    else {
        Write-Host "  ✓ Virtual environment already exists" -ForegroundColor Green
    }
    
    # Activate venv
    Write-Host "  Activating virtual environment..." -ForegroundColor Gray
    & "backend/venv/Scripts/Activate.ps1"
    
    # Install dependencies
    Write-Host "  Installing dependencies..." -ForegroundColor Gray
    pip install -q -r backend/requirements.txt
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ✗ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✓ Dependencies installed" -ForegroundColor Green
}

function Invoke-Migrations {
    Write-Host ""
    Write-Host "Running database migrations..." -ForegroundColor Yellow
    
    Write-Host "  Applying migrations with Alembic..." -ForegroundColor Gray
    Set-Location backend
    alembic upgrade head
    Set-Location ..
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Migrations applied successfully" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "  ✗ Migration failed" -ForegroundColor Red
        return $false
    }
}

function Start-LocalServer {
    Write-Host ""
    Write-Host "Starting NovaDraw AI Backend (Local)..." -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    
    Initialize-Environment
    
    if (-not (Test-Python)) {
        exit 1
    }
    
    Setup-VirtualEnvironment
    
    if (-not (Invoke-Migrations)) {
        exit 1
    }
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Starting development server..." -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Backend API:  http://localhost:8000" -ForegroundColor White
    Write-Host "API Docs:     http://localhost:8000/docs" -ForegroundColor White
    Write-Host "ReDoc:        http://localhost:8000/redoc" -ForegroundColor White
    Write-Host "Health Check: http://localhost:8000/health" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""
    
    Set-Location backend
    uvicorn main:app --reload --host 0.0.0.0 --port 8000
}

function Stop-LocalServer {
    Write-Host "Stopping local server..." -ForegroundColor Cyan
    
    # Kill any Python processes running uvicorn on port 8000
    $processes = Get-Process python -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "python" }
    
    if ($processes) {
        foreach ($process in $processes) {
            try {
                Stop-Process -Id $process.Id -Force
                Write-Host "Stopped process ID: $($process.Id)" -ForegroundColor Green
            }
            catch {
                Write-Host "Could not stop process ID: $($process.Id)" -ForegroundColor Yellow
            }
        }
    }
    else {
        Write-Host "No running server found" -ForegroundColor Yellow
    }
}

function Show-Status {
    Write-Host ""
    Write-Host "Server Status:" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Server is running at http://localhost:8000" -ForegroundColor Green
            Write-Host ""
            Write-Host "API Docs:     http://localhost:8000/docs" -ForegroundColor White
            Write-Host "ReDoc:        http://localhost:8000/redoc" -ForegroundColor White
        }
    }
    catch {
        Write-Host "✗ Server is not running" -ForegroundColor Red
        Write-Host ""
        Write-Host "Start the server with: .\start-server-local.ps1 start" -ForegroundColor Yellow
    }
}

function Reset-Everything {
    Write-Host "WARNING: This will delete the virtual environment and reset the database!" -ForegroundColor Red
    Write-Host "Press any key to continue or Ctrl+C to cancel..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Write-Host ""
    Write-Host "Removing virtual environment..." -ForegroundColor Cyan
    
    if (Test-Path "backend/venv") {
        Remove-Item -Recurse -Force "backend/venv"
        Write-Host "✓ Virtual environment removed" -ForegroundColor Green
    }
    else {
        Write-Host "Virtual environment not found" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "To reset the database, delete your .env file and run 'start' again." -ForegroundColor Yellow
    Write-Host "Or manually delete the database file specified in DATABASE_URL." -ForegroundColor Yellow
}

# Main execution
switch ($Command) {
    "start" { Start-LocalServer }
    "stop" { Stop-LocalServer }
    "migrate" { 
        Initialize-Environment
        Setup-VirtualEnvironment
        Invoke-Migrations
    }
    "status" { Show-Status }
    "reset" { Reset-Everything }
    default { Show-Menu }
}
