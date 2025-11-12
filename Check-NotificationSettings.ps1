Write-Host "=== Diagnóstico das Configurações de Notificação do Windows ===" -ForegroundColor Cyan

# Verificar configurações globais de notificação
Write-Host "`n1. Configurações Globais de Notificação:" -ForegroundColor Yellow
try {
    $toastHabilitado = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -ErrorAction SilentlyContinue
    if ($toastHabilitado) {
        if ($toastHabilitado.ToastEnabled -eq 1) {
            Write-Host "   ✓ Notificações toast estão HABILITADAS" -ForegroundColor Green
        } else {
            Write-Host "   ✗ Notificações toast estão DESABILITADAS" -ForegroundColor Red
        }
    } else {
        Write-Host "   ? Configuração de notificação toast não encontrada (pode estar habilitada por padrão)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ Não foi possível verificar as configurações de notificação toast" -ForegroundColor Red
}

# Verificar Assistente de Foco
Write-Host "`n2. Configurações do Assistente de Foco:" -ForegroundColor Yellow
try {
    $caminhoAssistenteFoco = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount"
    $assistenteFoco = Get-ChildItem $caminhoAssistenteFoco -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*windows.data.notifications.quiethours*" }
    if ($assistenteFoco) {
        Write-Host "   ? Configurações do Assistente de Foco encontradas - pode estar ativo" -ForegroundColor Yellow
    } else {
        Write-Host "   ✓ Assistente de Foco provavelmente não está bloqueando notificações" -ForegroundColor Green
    }
} catch {
    Write-Host "   ? Não foi possível determinar o status do Assistente de Foco" -ForegroundColor Yellow
}

# Verificar se o PowerShell está registrado para notificações
Write-Host "`n3. Registro de Notificações do PowerShell:" -ForegroundColor Yellow
$caminhoRegistro = "HKCU:\SOFTWARE\Classes\AppUserModelId\PowerShell.Notificacoes"
if (Test-Path $caminhoRegistro) {
    Write-Host "   ✓ PowerShell está registrado para notificações" -ForegroundColor Green
} else {
    Write-Host "   ✗ PowerShell NÃO está registrado para notificações" -ForegroundColor Red
    Write-Host "     Tentará registrar ao executar notificações" -ForegroundColor Gray
}

# Testar disponibilidade da API Windows Runtime
Write-Host "`n4. Teste da API Windows Runtime:" -ForegroundColor Yellow
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    Write-Host "   ✓ APIs de notificação do Windows Runtime estão disponíveis" -ForegroundColor Green
} catch {
    Write-Host "   ✗ APIs de notificação do Windows Runtime NÃO estão disponíveis" -ForegroundColor Red
    Write-Host "     Erro: $($_.Exception.Message)" -ForegroundColor Red
}

# Verificar versão do Windows
Write-Host "`n5. Versão do Windows:" -ForegroundColor Yellow
$versao = [Environment]::OSVersion.Version
if ($versao.Major -ge 10) {
    Write-Host "   ✓ Windows 10/11 detectado (suporta notificações toast)" -ForegroundColor Green
} else {
    Write-Host "   ✗ Versão mais antiga do Windows detectada (pode não suportar notificações toast)" -ForegroundColor Red
}

Write-Host "`n=== Recomendações ===" -ForegroundColor Cyan
Write-Host "1. Se as notificações toast estiverem desabilitadas, habilite em Configurações > Sistema > Notificações" 
Write-Host "2. Se o Assistente de Foco estiver ativo, desabilite ou adicione o PowerShell como exceção"
Write-Host "3. Tente executar o script de notificação - ele tentará registrar o PowerShell automaticamente"
Write-Host "4. Se as notificações toast ainda falharem, use o parâmetro -UsarFallback para notificações balão confiáveis"