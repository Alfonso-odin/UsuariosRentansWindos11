# Verifica si se ejecuta como administrador
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "❌ Este script debe ejecutarse como administrador."
    Pause
    Exit
}

Write-Host "`n💻 Script ejecutando Creado por ODIN."

# 1. Cambiar nombre del usuario local
$currentUser = $env:USERNAME
Write-Host "`nUsuario actual: $currentUser"

$newUsername = Read-Host "1. Nuevo nombre de la cuenta (usuario local)"
if (Get-LocalUser -Name $newUsername -ErrorAction SilentlyContinue) {
    Write-Host "❌ El usuario '$newUsername' ya existe. Cancelando."
    exit
}

Rename-LocalUser -Name $currentUser -NewName $newUsername

# 2. Cambiar nombre completo del usuario
$fullName = Read-Host "2. Nombre completo para mostrar del usuario"
Set-LocalUser -Name $newUsername -FullName $fullName

# 3. Cambiar descripción del usuario
$userDescription = Read-Host "3. Descripción del usuario"
Set-LocalUser -Name $newUsername -Description $userDescription

# 4. Establecer contraseña con validación y confirmación visual con bucle
$continueLoop = $true
do {
    Write-Host "`n=== Configuración de contraseña para '$newUsername' ==="
    $password1 = Read-Host "4. Nueva contraseña" -AsSecureString
    $password2 = Read-Host "Confirma la nueva contraseña" -AsSecureString

    # Método nativo, seguro y sin errores de codificación para Windows 11
    $p1 = [System.Net.NetworkCredential]::new("", $password1).Password
    $p2 = [System.Net.NetworkCredential]::new("", $password2).Password

    if ($p1 -ne $p2) {
        Write-Host "❌ Las contraseñas no coinciden. Vuelve a intentarlo."
        continue
    }

    # Mostrar al usuario la contraseña establecida
    Write-Host "`n✅ Contraseña confirmada: '$p1'"
    $confirmFinal = Read-Host "¿Deseas usar esta contraseña? (si/no)"

    if ($confirmFinal.ToLower() -eq "si") {
        try {
            # Se aplica ErrorAction Stop para capturar fallos de Windows
            Set-LocalUser -Name $newUsername -Password $password1 -ErrorAction Stop
            Write-Host "🔐 Contraseña establecida correctamente."
            $continueLoop = $false
        }
        catch {
            Write-Host "❌ Error al establecer la contraseña: $_"
            Write-Host "⚠️ Es muy probable que la contraseña no cumpla con las políticas de seguridad de Windows (longitud, mayúsculas, números)."
            Write-Host "🔄 Reiniciando paso 4..."
        }
    }
    else {
        Write-Host "🔄 Reiniciando paso 4 para configurar otra contraseña..."
    }

} while ($continueLoop)

# 5. Cambiar nombre del equipo
$newPCName = Read-Host "5. Nuevo nombre del equipo (máx 15 caracteres, letras/números/guiones)"
if ($newPCName.Length -gt 15 -or $newPCName -match '[^a-zA-Z0-9\-]') {
    Write-Host "❌ Nombre de equipo inválido. Cancelando."
    exit
}
Rename-Computer -NewName $newPCName -Force

# 6. Cambiar descripción del equipo
$description = Read-Host "6. Descripción del equipo"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name srvcomment -Value $description

# 7. Cambiar grupo de trabajo
$workgroup = Read-Host "7. Nuevo grupo de trabajo"
Add-Computer -WorkGroupName $workgroup -Force

# 8. Ejecutar Autologon
$rutasAutologon = @(
    "C:\SW ADMIN\SOFT\Autologon.exe",
    "C:\SW SCN\GENERAL\Autologon.exe"
)

$autologonEjecutado = $false

foreach ($ruta in $rutasAutologon) {
    if (Test-Path $ruta) {
        Write-Host "`n🔐 Configurando Autologon de forma silenciosa..."
        
        # El formato de Autologon.exe es: Autologon.exe usuario dominio contraseña
        # Usamos el nombre del equipo como dominio para cuentas locales
        $argumentos = "/accepteula $newUsername $newPCName ""$p1"""
        
        # Ejecutamos el proceso pasándole los argumentos y ocultando ventanas extra
        Start-Process -FilePath $ruta -ArgumentList $argumentos -Wait -NoNewWindow
        
        Write-Host "✅ Autologon inyectado en el registro correctamente desde: $ruta"
        $autologonEjecutado = $true
        break
    }
}

if (-not $autologonEjecutado) {
    Write-Host "⚠️ No se encontró Autologon.exe en las rutas especificadas. El inicio de sesión automático no se configuró."
}

# 9. Cambios aplicados
Write-Host "`n✅ Todos los cambios fueron aplicados correctamente."

# 10. Preguntar si desea reiniciar
$restart = Read-Host "`n¿Deseas reiniciar el sistema ahora? (si/no)"
if ($restart.ToLower() -eq "si") {
    Write-Host "`n🔄 Reiniciando el sistema..."
    Restart-Computer -Force
} else {
    Write-Host "`n⚠️ Reinicio cancelado. Algunos cambios requerirán reinicio para aplicar completamente."
    Pause
}

Pause