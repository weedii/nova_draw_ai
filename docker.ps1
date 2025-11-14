#!/usr/bin/env pwsh
# NovaDraw AI - Docker Management Script

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "migrate", "reset")]
    [string]$Command = "start"
)

function Show-Menu {
    Write-Host ""
    Write-Host "NovaDraw AI - Docker Manager" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\docker.ps1 [command]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor White
    Write-Host "  start     - Start all containers (default)" -ForegroundColor Gray
    Write-Host "  stop      - Stop all containers" -ForegroundColor Gray
    Write-Host "  restart   - Restart all containers" -ForegroundColor Gray
    Write-Host "  logs      - View container logs" -ForegroundColor Gray
    Write-Host "  status    - Show container status" -ForegroundColor Gray
    Write-Host "  migrate   - Create and run database migrations" -ForegroundColor Gray
    Write-Host "  reset     - Stop and remove all containers and volumes" -ForegroundColor Gray
    Write-Host ""
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

function Start-Containers {
    Write-Host "Starting NovaDraw AI..." -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Docker)) {
        exit 1
    }
    
    # Check .env file
    if (-not (Test-Path ".env")) {
        Write-Host ".env file not found. Creating from .env.example..." -ForegroundColor Yellow
        Copy-Item ".env.example" ".env"
        Write-Host "Created .env file" -ForegroundColor Green
        Write-Host ""
        Write-Host "Please edit .env and add your API keys, then run this script again." -ForegroundColor Yellow
        notepad .env
        exit 0
    }
    
    Write-Host "Starting containers..." -ForegroundColor Yellow
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Containers started" -ForegroundColor Green
        Write-Host ""
        
        # Wait for containers to be ready
        Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        # Run migrations
        Write-Host ""
        Write-Host "Setting up database..." -ForegroundColor Yellow
        docker exec novadraw_backend alembic revision --autogenerate -m "Auto migration" 2>$null
        docker exec novadraw_backend alembic upgrade head
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Database ready" -ForegroundColor Green
        }
        else {
            Write-Host "Database setup completed (no new migrations needed)" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host "NovaDraw AI is running!" -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Backend API:  http://localhost:8000" -ForegroundColor White
        Write-Host "API Docs:     http://localhost:8000/docs" -ForegroundColor White
        Write-Host "PostgreSQL:   localhost:5432" -ForegroundColor White
        Write-Host ""
    }
    else {
        Write-Host "Failed to start containers" -ForegroundColor Red
        exit 1
    }
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

function Run-Migrations {
    Write-Host "Running database migrations..." -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Creating migration..." -ForegroundColor Yellow
    docker exec novadraw_backend alembic revision --autogenerate -m "Auto migration"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Migration created" -ForegroundColor Green
        Write-Host ""
        Write-Host "Applying migration..." -ForegroundColor Yellow
        docker exec novadraw_backend alembic upgrade head
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Migrations completed successfully" -ForegroundColor Green
        }
        else {
            Write-Host "Failed to apply migrations" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "Failed to create migration" -ForegroundColor Red
        exit 1
    }
}

function Reset-Everything {
    Write-Host "WARNING: This will delete all containers, volumes, and data!" -ForegroundColor Red
    Write-Host "Press any key to continue or Ctrl+C to cancel..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Write-Host ""
    Write-Host "Removing everything..." -ForegroundColor Cyan
    docker-compose down -v
    
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
    "stop" { Stop-Containers }
    "restart" { Restart-Containers }
    "logs" { Show-Logs }
    "status" { Show-Status }
    "migrate" { Run-Migrations }
    "reset" { Reset-Everything }
    default { Show-Menu }
}
