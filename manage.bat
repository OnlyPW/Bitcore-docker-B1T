@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Bit Core Docker Management
echo ========================================
echo.

:menu
echo Please select an option:
echo.
echo 1. Start Bit Core
echo 2. Stop Bit Core
echo 3. Restart Bit Core
echo 4. View Logs
echo 5. Check Status
echo 6. Update Configuration
echo 7. Clean Data (WARNING: Deletes blockchain data)
echo 8. Exit
echo.
set /p choice="Enter your choice (1-8): "

if "%choice%"=="1" goto start
if "%choice%"=="2" goto stop
if "%choice%"=="3" goto restart
if "%choice%"=="4" goto logs
if "%choice%"=="5" goto status
if "%choice%"=="6" goto update_config
if "%choice%"=="7" goto clean_data
if "%choice%"=="8" goto exit
echo Invalid choice. Please try again.
echo.
goto menu

:start
echo.
echo Starting Bit Core...
docker compose up -d
if %errorlevel% equ 0 (
    echo Bit Core started successfully!
) else (
    echo Failed to start Bit Core
)
echo.
pause
goto menu

:stop
echo.
echo Stopping Bit Core...
docker compose down
if %errorlevel% equ 0 (
    echo Bit Core stopped successfully!
) else (
    echo Failed to stop Bit Core
)
echo.
pause
goto menu

:restart
echo.
echo Restarting Bit Core...
docker compose down
docker compose up -d
if %errorlevel% equ 0 (
    echo Bit Core restarted successfully!
) else (
    echo Failed to restart Bit Core
)
echo.
pause
goto menu

:logs
echo.
echo Viewing Bit Core logs (Press Ctrl+C to exit)...
echo.
docker compose logs -f
goto menu

:status
echo.
echo Bit Core Status:
echo.
docker compose ps
echo.
echo Container Details:
docker compose logs --tail=10
echo.
pause
goto menu

:update_config
echo.
echo Updating configuration...
echo.
echo This will restart Bit Core with the updated config/bit.conf template.
echo.
set /p confirm="Continue? (y/N): "
if /i "%confirm%"=="y" (
    echo Stopping Bit Core...
    docker compose down
    echo Removing old configuration...
    if exist "data\bit.conf" del "data\bit.conf"
    echo Starting Bit Core with new configuration...
    docker compose up -d
    echo Configuration updated successfully!
) else (
    echo Update cancelled.
)
echo.
pause
goto menu

:clean_data
echo.
echo WARNING: This will delete ALL blockchain data!
echo This includes:
echo - Wallet data
echo - Blockchain blocks
echo - Transaction index
echo - All other Bit Core data
echo.
set /p confirm="Are you sure you want to continue? Type 'DELETE' to confirm: "
if "%confirm%"=="DELETE" (
    echo Stopping Bit Core...
    docker compose down
    echo Removing all data...
    if exist "data" rmdir /s /q "data"
    mkdir data
    echo Starting Bit Core with fresh data...
    docker compose up -d
    echo Data cleaned successfully!
) else (
    echo Clean cancelled.
)
echo.
pause
goto menu

:exit
echo.
echo Goodbye!
exit /b 0
