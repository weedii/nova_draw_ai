#!/usr/bin/env pwsh
# NovaDraw AI - Server Management Script
# Handles: environment setup, database migrations, and server startup

param(
    [Parameter(Position = 0)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "migrate", "reset", "dev")]
    [string]$Command = "start",
    
    [switch]$Build = $false
)

function Show-Menu {
    Write-Host ""
    Write-Host "NovaDraw AI - Server Manager" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\start-server.ps1 [command] [-Build]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor White
    Write-Host "  start     - Start server with Docker (default)" -ForegroundColor Gray
    Write-Host "  dev       - Start server locally (no Docker)" -ForegroundColor Gray
    Write-Host "  stop      - Stop all containers" -ForegroundColor Gray
    Write-Host "  restart   - Restart all containers" -ForegroundColor Gray
    Write-Host "  logs      - View container logs" -ForegroundColor Gray
    Write-Host "  status    - Show container status" -ForegroundColor Gray
    Write-Host "  migrate   - Run database migrations" -ForegroundColor Gray
    Write-Host "  reset     - Stop and remove all containers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  -Build    - Rebuild Docker image before starting" -ForegroundColor Gray
    Write-Host ""
}

# Load environment variables from .env
function Load-Environment {
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

function Test-Docker {
    try {
        docker info | Out-Null
        return $true
    }
    catch {
        Write-Host "Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
        return $false
    }
}

function Invoke-Migrations {
    Write-Host "Running database migrations..." -ForegroundColor Yellow
    
    Write-Host "  Applying migrations with Alembic..." -ForegroundColor Gray
    docker exec novadraw_server alembic upgrade head
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Migrations applied successfully" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "  ✗ Migration failed" -ForegroundColor Red
        return $false
    }
}

function Start-Containers {
    Write-Host ""
    Write-Host "Starting NovaDraw AI Backend..." -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    
    Load-Environment
    
    if (-not (Test-Docker)) {
        exit 1
    }
    
    Write-Host ""
    Write-Host "Starting Docker containers..." -ForegroundColor Yellow
    if ($Build) {
        docker-compose up --build -d
    }
    else {
        docker-compose up -d
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to start containers" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Containers started" -ForegroundColor Green
    
    # Wait for server to be ready
    Write-Host ""
    Write-Host "Waiting for server to be ready..." -ForegroundColor Yellow
    $maxAttempts = 30
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET -UseBasicParsing -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Host "Server is ready!" -ForegroundColor Green
                break
            }
        }
        catch {
            # Server not ready yet
        }
        $attempt++
        Start-Sleep -Seconds 1
    }
    
    if ($attempt -ge $maxAttempts) {
        Write-Host "Server took too long to start. Check logs with: docker-compose logs" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Running database migrations..." -ForegroundColor Yellow
    if (Invoke-Migrations) {
        Write-Host ""
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host "✓ NovaDraw AI Backend is running!" -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Backend API:  http://localhost:8000" -ForegroundColor White
        Write-Host "API Docs:     http://localhost:8000/docs" -ForegroundColor White
        Write-Host "ReDoc:        http://localhost:8000/redoc" -ForegroundColor White
        Write-Host ""
    }
    else {
        Write-Host "Migrations failed. Check logs with: docker-compose logs" -ForegroundColor Red
        exit 1
    }
}

function Start-Development {
    Write-Host ""
    Write-Host "Starting NovaDraw AI Backend (Development Mode)..." -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    
    Load-Environment
    
    Write-Host ""
    Write-Host "Checking Python environment..." -ForegroundColor Yellow
    
    # Check if venv exists
    if (-not (Test-Path "backend/venv")) {
        Write-Host "Virtual environment not found. Creating..." -ForegroundColor Yellow
        python -m venv backend/venv
    }
    
    # Activate venv
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    & "backend/venv/Scripts/Activate.ps1"
    
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    pip install -q -r backend/requirements.txt
    
    Write-Host ""
    Write-Host "Running database migrations..." -ForegroundColor Yellow
    Set-Location backend
    alembic upgrade head
    Set-Location ..
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Migrations failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Starting development server..." -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Backend API:  http://localhost:8000" -ForegroundColor White
    Write-Host "API Docs:     http://localhost:8000/docs" -ForegroundColor White
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""
    
    Set-Location backend
    uvicorn main:app --reload --host 0.0.0.0 --port 8000
}

function Stop-Containers {
    Write-Host "Stopping containers..." -ForegroundColor Cyan
    docker-compose down
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Containers stopped" -ForegroundColor Green
    }
    else {
        Write-Host "Failed to stop containers" -ForegroundColor Red
        exit 1
    }
}

function Restart-Containers {
    Write-Host "Restarting containers..." -ForegroundColor Cyan
    docker-compose restart
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Containers restarted" -ForegroundColor Green
        Write-Host ""
        Write-Host "Backend API:  http://localhost:8000" -ForegroundColor White
    }
    else {
        Write-Host "Failed to restart containers" -ForegroundColor Red
        exit 1
    }
}

function Show-Logs {
    Write-Host "Viewing logs (Press Ctrl+C to exit)..." -ForegroundColor Cyan
    Write-Host ""
    docker-compose logs -f
}

function Show-Status {
    Write-Host "Container Status:" -ForegroundColor Cyan
    Write-Host ""
    docker-compose ps
}

function Reset-Everything {
    Write-Host "WARNING: This will delete all containers and stop all services!" -ForegroundColor Red
    Write-Host "Press any key to continue or Ctrl+C to cancel..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Write-Host ""
    Write-Host "Stopping and removing containers..." -ForegroundColor Cyan
    docker-compose down
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Everything removed" -ForegroundColor Green
    }
    else {
        Write-Host "Failed to remove containers" -ForegroundColor Red
        exit 1
    }
}

# Main execution
switch ($Command) {
    "start" { Start-Containers }
    "dev" { Start-Development }
    "stop" { Stop-Containers }
    "restart" { Restart-Containers }
    "logs" { Show-Logs }
    "status" { Show-Status }
    "migrate" { Invoke-Migrations }
    "reset" { Reset-Everything }
    default { Show-Menu }
}
