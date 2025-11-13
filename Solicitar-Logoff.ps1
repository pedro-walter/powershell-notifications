[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = "Titulo da janela do popup")]
    [string]$Titulo = "Acesso de Administrador Concedido",

    [Parameter(Mandatory = $false, HelpMessage = "Mensagem a ser exibida")]
    [string]$Mensagem = "Seu acesso de administrador foi concedido.`n`nPara aplicar as permissoes, e necessario fazer logoff.`n`nDeseja fazer logoff agora?",

    [Parameter(Mandatory = $false, HelpMessage = "Tempo em segundos para timeout automatico (0 = sem timeout)")]
    [int]$Timeout = 0,

    [Parameter(Mandatory = $false, HelpMessage = "Tempo de espera antes do logoff em segundos")]
    [int]$DelayLogoff = 3
)

$ErrorActionPreference = "Stop"

try {
    # Importar o modulo
    $CaminhoModulo = Join-Path $PSScriptRoot "PopupLogoff.psm1"

    if (-not (Test-Path $CaminhoModulo)) {
        throw "Modulo PopupLogoff.psm1 nao encontrado em: $CaminhoModulo"
    }

    Import-Module $CaminhoModulo -Force

    # Chamar a funcao
    $executouLogoff = Show-PopupLogoff -Titulo $Titulo -Mensagem $Mensagem -Timeout $Timeout -DelayLogoff $DelayLogoff -Verbose

    # Informar resultado
    if ($executouLogoff) {
        Write-Host "Logoff sera executado..." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Logoff cancelado pelo usuario" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Error "Erro ao solicitar logoff: $($_.Exception.Message)"
    exit 2
}