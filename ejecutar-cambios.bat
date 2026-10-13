@echo off
color 0B
title Iniciando Configuracion Avanzada...

:: 1. Comprobar permisos de administrador silenciosamente
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :RunScript
) else (
    echo 🛡️ Solicitando permisos de administrador automaticamente...
    :: Lanza el mismo .bat pero pidiendo elevacion de privilegios
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:RunScript
:: 2. Configurar la ruta del script de PowerShell
set SCRIPT_PATH=C:\Usuarios Rentas\cambiar-config-avanzado.ps1

if not exist "%SCRIPT_PATH%" (
    color 0C
    echo ❌ No se encontro el archivo PowerShell en: %SCRIPT_PATH%
    pause
    exit /b
)

:: 3. Ejecutar el script saltando las politicas de restriccion
echo 🚀 Ejecutando script de configuracion avanzada...
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Maximized -File "%SCRIPT_PATH%"

echo.
echo ✅ Proceso por lotes finalizado.
pause