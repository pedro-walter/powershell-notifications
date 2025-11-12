# Script para habilitar notificacoes do Windows via registro
Write-Host "=== Habilitando Notificacoes do Windows ===" -ForegroundColor Cyan

# Caminho do registro para notificacoes
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"

# Verificar se o caminho existe
if (-not (Test-Path $regPath)) {
    Write-Host "Criando chave de registro..." -ForegroundColor Yellow
    New-Item -Path $regPath -Force | Out-Null
}

# Verificar estado atual
$current = Get-ItemProperty -Path $regPath -Name "ToastEnabled" -ErrorAction SilentlyContinue

if ($current) {
    Write-Host "Estado atual: ToastEnabled = $($current.ToastEnabled)" -ForegroundColor Yellow
} else {
    Write-Host "ToastEnabled nao encontrado no registro" -ForegroundColor Yellow
}

# Habilitar notificacoes toast
Write-Host "`nHabilitando notificacoes..." -ForegroundColor Cyan
Set-ItemProperty -Path $regPath -Name "ToastEnabled" -Value 1 -Type DWord

# Verificar se foi aplicado
$new = Get-ItemProperty -Path $regPath -Name "ToastEnabled" -ErrorAction SilentlyContinue
if ($new.ToastEnabled -eq 1) {
    Write-Host "Notificacoes habilitadas com sucesso!" -ForegroundColor Green
} else {
    Write-Host "Erro ao habilitar notificacoes" -ForegroundColor Red
}

# Verificar Foco Assistido
Write-Host "`n=== Verificando Foco Assistido ===" -ForegroundColor Cyan
$quietHoursPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"

if (Test-Path $quietHoursPath) {
    $quietHours = Get-ItemProperty -Path $quietHoursPath -ErrorAction SilentlyContinue

    if ($quietHours.PSObject.Properties.Name -contains "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND") {
        Write-Host "Configuracao de som: $($quietHours.NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND)" -ForegroundColor Yellow
    }

    if ($quietHours.PSObject.Properties.Name -contains "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK") {
        Write-Host "Notificacoes acima da tela de bloqueio: $($quietHours.NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Recomendacoes ===" -ForegroundColor Cyan
Write-Host "1. As notificacoes foram habilitadas no registro"
Write-Host "2. Pode ser necessario fazer logout/login ou reiniciar o Windows"
Write-Host "3. Teste: .\Show-Popup.ps1 Teste Notificacao"
Write-Host "4. Fallback: .\Show-Popup.ps1 Teste Fallback -UsarFallback"