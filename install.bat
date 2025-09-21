@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Bit Core Docker Installation
echo ========================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not installed or not in PATH
    echo Please install Docker Desktop from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM Check if Docker Compose is available
docker compose version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker Compose is not available
    echo Please ensure Docker Desktop is running and up to date
    pause
    exit /b 1
)

echo Docker and Docker Compose are available
echo.

REM Create directories if they don't exist
if not exist "config" mkdir config
if not exist "data" mkdir data

echo Directories created/verified
echo.

REM Build the Docker image
echo Building Bit Core Docker image...
docker compose build
if %errorlevel% neq 0 (
    echo ERROR: Failed to build Docker image
    pause
    exit /b 1
)

echo.
echo Docker image built successfully!
echo.

REM Start the container
echo Starting Bit Core container...
docker compose up -d
if %errorlevel% neq 0 (
    echo ERROR: Failed to start container
    pause
    exit /b 1
)

echo.
echo ========================================
echo    Installation completed successfully!
echo ========================================
echo.
echo Bit Core is now running in Docker
echo.
echo Useful commands:
echo   docker compose ps          - Check container status
echo   docker compose logs -f     - View logs
echo   docker compose down        - Stop container
echo   docker compose up -d       - Start container
echo.
echo Configuration files:
echo   config/bit.conf            - Configuration template
echo   data/bit.conf              - Active configuration
echo   data/                      - Blockchain data directory
echo.
echo RPC Access:
echo   Host: localhost
echo   Port: 8332
echo   User: user (default)
echo   Password: changeme (default)
echo.
echo Press any key to view container status...
pause >nul

echo.
echo Container Status:
docker compose ps

echo.
echo Press any key to exit...
pause >nul
