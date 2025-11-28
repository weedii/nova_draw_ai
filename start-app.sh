#!/bin/bash

# FastAPI Backend Startup Script for Linux/macOS

# Parse command line arguments
rebuild=false
fresh=false
port=8000
help=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -rebuild|--rebuild)
            rebuild=true
            shift
            ;;
        -fresh|--fresh)
            fresh=true
            shift
            ;;
        -port|--port)
            port="$2"
            shift 2
            ;;
        -help|--help|-h)
            help=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Log function
log() {
    local message="$1"
    local type="${2:-info}"
    
    case $type in
        success)
            echo -e "${GREEN}${message}${NC}"
            ;;
        error)
            echo -e "${RED}${message}${NC}"
            ;;
        warning)
            echo -e "${YELLOW}${message}${NC}"
            ;;
        info)
            echo -e "${CYAN}${message}${NC}"
            ;;
        header)
            echo -e "${MAGENTA}${message}${NC}"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Show help
if [ "$help" = true ]; then
    echo "FastAPI Backend Startup Script"
    echo ""
    echo "Usage: ./start-app.sh [-rebuild] [-fresh] [-port 8001] [-help]"
    echo ""
    echo "Options:"
    echo "  -rebuild   Rebuild venv and reinstall requirements"
    echo "  -fresh     Delete and recreate venv"
    echo "  -port      Custom port (default 8000)"
    echo "  -help      Show this help"
    exit 0
fi

# Set up paths
sd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bd="$sd/backend"
vp="$bd/venv"
pe="$vp/bin/python"
pi="$vp/bin/pip"
rf="$bd/requirements.txt"
mf="$bd/main.py"

log "=====================================================================" "header"
log "           NovaDraw FastAPI Backend Startup Script" "header"
log "=====================================================================" "header"
log ""

log "[1/4] Checking Python Virtual Environment..." "info"

if [ "$fresh" = true ] && [ -d "$vp" ]; then
    log "  -> Deleting existing venv..." "warning"
    rm -rf "$vp"
    if [ $? -eq 0 ]; then
        log "  [OK] Venv deleted" "success"
    else
        log "  [ERROR] Failed to delete venv" "error"
        exit 1
    fi
fi

if [ ! -d "$vp" ]; then
    log "  -> Creating new venv..." "warning"
    python3 -m venv "$vp"
    if [ $? -ne 0 ]; then
        log "  [ERROR] Failed to create venv" "error"
        exit 1
    fi
    log "  [OK] Venv created" "success"
    rebuild=true
else
    log "  [OK] Venv exists" "success"
fi

log "[2/4] Activating Virtual Environment..." "info"

if [ ! -f "$pe" ]; then
    log "  [ERROR] Python executable not found in venv" "error"
    exit 1
fi

log "  [OK] Venv activated" "success"

log "[3/4] Managing Dependencies..." "info"

if [ "$rebuild" = true ]; then
    log "  -> Reinstalling requirements..." "warning"
    if [ ! -f "$rf" ]; then
        log "  [ERROR] requirements.txt not found" "error"
        exit 1
    fi
    log "  -> Upgrading pip..." "info"
    "$pe" -m pip install --upgrade pip
    if [ $? -ne 0 ]; then
        log "  [ERROR] Failed to upgrade pip" "error"
        exit 1
    fi
    log "  -> Installing requirements..." "info"
    "$pi" install -r "$rf"
    if [ $? -ne 0 ]; then
        log "  [ERROR] Failed to install requirements" "error"
        exit 1
    fi
    log "  [OK] Requirements installed" "success"
else
    log "  -> Checking packages..." "info"
    package_count=$("$pi" list --format=json 2>/dev/null | grep -c '"name"' || echo 0)
    if [ "$package_count" -lt 5 ]; then
        log "  -> Installing requirements..." "warning"
        "$pi" install -r "$rf"
        if [ $? -ne 0 ]; then
            log "  [ERROR] Failed to install requirements" "error"
            exit 1
        fi
        log "  [OK] Requirements installed" "success"
    else
        log "  [OK] Requirements already installed" "success"
    fi
fi

log "[4/4] Starting FastAPI Application..." "info"
log ""

if [ ! -f "$mf" ]; then
    log "  [ERROR] main.py not found" "error"
    exit 1
fi

log "=====================================================================" "header"
log "                    Server Configuration" "header"
log "=====================================================================" "header"
log "  Host:          127.0.0.1" "info"
log "  Port:          $port" "info"
log "  App:           main:app" "info"
log "  Reload:        Enabled" "info"
log ""
log "  API URL: http://127.0.0.1:$port" "success"
log "  Docs:    http://127.0.0.1:$port/docs" "success"
log ""
log "Press Ctrl+C to stop the server" "warning"
log ""

cd "$bd"
"$pe" -m uvicorn main:app --host 127.0.0.1 --port "$port" --reload --log-level info
exit_code=$?
cd - > /dev/null

log ""
log "Application stopped" "warning"
exit $exit_code
