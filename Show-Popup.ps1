[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "A mensagem a ser exibida na notificação")]
    [string]$Mensagem,
    
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "O título da notificação")]
    [string]$Titulo = "Notificação",
    
    [Parameter(Mandatory = $false, HelpMessage = "Usar balão da bandeja do sistema como fallback em vez de notificação toast")]
    [switch]$UsarFallback,
    
    [Parameter(Mandatory = $false, HelpMessage = "Tornar a notificação persistente (só desaparece quando dispensada manualmente)")]
    [switch]$Persistente
)

$ErrorActionPreference = "Stop"

try {
    $CaminhoModulo = Join-Path $PSScriptRoot "WindowsNotification.psm1"
    
    if (-not (Test-Path $CaminhoModulo)) {
        throw "Módulo WindowsNotification não encontrado em: $CaminhoModulo"
    }
    
    Import-Module $CaminhoModulo -Force
    
    $resultado = Show-NotificacaoWindows -Mensagem $Mensagem -Titulo $Titulo -UsarFallback:$UsarFallback -Persistente:$Persistente
    
    if ($resultado) {
        Write-Host "Notificação enviada com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "Falha ao enviar notificação." -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Error "Erro ao enviar notificação: $($_.Exception.Message)"
    exit 1
}