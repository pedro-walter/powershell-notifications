# Script para limpar registro do PowerShell para notificações
# Necessário rodar caso queira mudar o título da janela de notificações (-DisplayName)
Write-Host "=== Limpando Registro de Notificações ===" -ForegroundColor Cyan

$caminhoRegistro = "HKCU:\SOFTWARE\Classes\AppUserModelId\PowerShell.Notificacoes"

if (Test-Path $caminhoRegistro) {
    Write-Host "Removendo registro antigo..." -ForegroundColor Yellow
    Remove-Item -Path $caminhoRegistro -Recurse -Force
    Write-Host "? Registro removido com sucesso!" -ForegroundColor Green
} else {
    Write-Host "? Nenhum registro anterior encontrado" -ForegroundColor Green
}

Write-Host "`nApós executar este script, execute uma notificação para recriar o registro com encoding correto." -ForegroundColor Cyan