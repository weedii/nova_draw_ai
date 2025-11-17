param(
    [string]$Build = "false"  # Default value for Build parameter
)

# Require administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run as Administrator"
    pause
    exit 1
}

Write-Host "== Loading Env ====================================================="  # Debug output
# Load environment variables from .env
foreach ($line in (Get-Content .env)) {
    if ($line -match '^\s*#') { continue }  # Skip comments
    if ($line -match '^\s*$') { continue }  # Skip empty lines
    if ($line -match '^([^=]+)=(.*)$') {
        # Match any key=value format
        $key = $matches[1].Trim()
        $value = $matches[2].Trim('"').Trim("'").Trim()  # Remove quotes if present
        if ($value) {
            # Only set if value is not empty
            [Environment]::SetEnvironmentVariable($key, $value)
            if ($key -eq 'LOCAL_AZURE_HOST') {
                Write-Host "Debug: Setting LOCAL_AZURE_HOST = '$value'"
            }
            Write-Host "Loaded $key = $value"  # Debug output
        }
    }
}
Write-Host "=================================================================="  # Debug output

function Wait-ForService {
    param (
        [string]$ServiceName,
        [string]$Url,
        [int]$MaxAttempts = 10,
        [int]$DelaySeconds = 2
    )
    
    Write-Host "Waiting for $ServiceName to be ready..."
    $attempt = 1
    
    while ($attempt -le $MaxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method GET -UseBasicParsing
            Write-Host "$ServiceName is ready!"
            return $true
        }
        catch {
            # If we get a 403, the service is up but we're not authorized - that's OK
            if ($_.Exception.Response.StatusCode.value__ -eq 403) {
                Write-Host "$ServiceName is ready! (403 is expected)"
                return $true
            }
            Write-Host "Waiting for $ServiceName (attempt $attempt/$MaxAttempts) - $($_.Exception.Message)"
            Start-Sleep -Seconds $DelaySeconds
            $attempt++
        }
    }
    
    Write-Error "$ServiceName failed to start after $MaxAttempts attempts"
    return $false
}

try {
    # ===== RESET PHASE =====
    Write-Host "=== Starting Reset Phase ==="
    
    Write-Host "Stopping all containers..."
    docker-compose down --remove-orphans -v

    Write-Host "Removing existing database volume..."
    docker volume rm duvee_postgres_data -f -ErrorAction SilentlyContinue

    Write-Host "Cleaning up temporary files..."
    Get-ChildItem -Path . -Recurse -Directory -Filter "__pycache__" | Remove-Item -Recurse -Force
    Remove-Item -Path "backend\.pytest_cache" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "azure-function\.pytest_cache" -Recurse -Force -ErrorAction SilentlyContinue

    # ===== SETUP PHASE =====
    Write-Host "=== Starting Setup Phase ==="

    Write-Host "Starting core services (database, storage, mailhog)..."
    # Start only the core services first
    if ($Build -eq "true") {
        docker-compose up --build -d duvee_db azurite mailhog
    }
    else {
        docker-compose up -d duvee_db azurite mailhog
    }

    Write-Host "Waiting for database to be ready..."
    do {
        $dbReady = docker-compose exec -T duvee_db pg_isready -U $env:POSTGRES_USER -d $env:POSTGRES_DB
        if (-not $dbReady) {
            Write-Host "Waiting for database..."
            Start-Sleep -Seconds 2
        }
    } while (-not $dbReady)

    $azuriteUrl = "http://$($env:LOCAL_AZURE_HOST):10000/devstoreaccount1?comp=list"
    
    # Wait for Azurite using environment connection string
    if (-not (Wait-ForService -ServiceName "Azurite" -Url $azuriteUrl)) {
        exit 1
    }

    Write-Host "Creating blob storage containers..."
    if (-not $env:LOCAL_STORAGE_CONNECTION_STRING) {
        Write-Error "Could not find Azure Storage connection string in .env file"
        exit 1
    }

    Write-Host "Creating storage containers..."
    $containers = @(
        @{name = "extracted-images"; access = "container" }, # Public access
        @{name = "documents"; access = "off" },              # Private
        @{name = "uploads"; access = "off" },                # Private
        @{name = "excel-files-temp"; access = "off" },       # Private
        @{name = "logs"; access = "off" },                   # Private
        @{name = "payroll-data"; access = "off" },           # Private
        @{name = "prompt-cache"; access = "off" }            # Private
    )

    foreach ($container in $containers) {
        Write-Host "Creating container: $($container.name) (access: $($container.access))"
        az storage container create --name $container.name `
            --connection-string $env:LOCAL_STORAGE_CONNECTION_STRING `
            --public-access $container.access `
            --auth-mode key
    }

    Write-Host "Creating storage queues..."
    $queues = @(
        "document-splitting-queue",
        "document-analysis-queue",
        "document-analysis-queue-poison",
        "document-splitting-queue-poison"
    )

    foreach ($queue in $queues) {
        Write-Host "Creating queue: $queue"
        az storage queue create --name $queue `
            --connection-string $env:LOCAL_STORAGE_CONNECTION_STRING `
            --auth-mode key
    }

    Write-Host "Storage containers and queues created successfully!"
    Write-Host "Starting backend service..."
    
    # Now start the backend
    if ($Build -eq "true") {
        docker-compose up --build -d backend
    }
    else {
        docker-compose up -d backend
    }

    # Wait for backend using environment URL
    if (-not (Wait-ForService -ServiceName "Backend" -Url "$env:LOCAL_BACKEND_URL/health")) {
        docker-compose logs backend
        exit 1
    }

    Write-Host "Running migrations and creating initial data..."
    docker-compose exec backend bash -c "alembic upgrade head && python -c 'from app.core.init_db import init_db; import asyncio; asyncio.run(init_db())'"

    Write-Host "Starting Azure Functions service..."
    # Finally start the Azure Functions - now that all containers/queues exist
    if ($Build -eq "true") {
        docker-compose up --build -d azure-function
    }
    else {
        docker-compose up -d azure-function
    }

    Write-Host "Waiting for Azure Functions to initialize..."
    Start-Sleep -Seconds 10  # Give Azure Functions time to initialize without errors

    Write-Host "=== Verifying Setup ==="
    Write-Host "Checking database connection..."
    docker-compose exec duvee_db psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -c "\l"
    
    Write-Host "Checking alembic version..."
    docker-compose exec backend alembic current
    
    Write-Host "Checking database URL..."
    docker-compose exec backend python -c "from app.core.config import settings; print(settings.DATABASE_URL)"

    Write-Host "=== Setup Complete ==="
    Write-Host "All services are now running with proper initialization order!"
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
finally {
    
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
} 