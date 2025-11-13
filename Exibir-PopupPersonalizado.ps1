[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = "Titulo do popup")]
    [string]$Titulo = "Acesso de Administrador Concedido",

    [Parameter(Mandatory = $false, HelpMessage = "Mensagem principal")]
    [string]$Mensagem = "Seu acesso de administrador foi concedido com sucesso!",

    [Parameter(Mandatory = $false, HelpMessage = "Texto secundario")]
    [string]$Subtexto = "Para aplicar as permissoes, e necessario fazer logoff e login novamente.",

    [Parameter(Mandatory = $false, HelpMessage = "Texto do botao de confirmacao")]
    [string]$TextoBotaoSim = "Fazer Logoff",

    [Parameter(Mandatory = $false, HelpMessage = "Texto do botao de cancelamento")]
    [string]$TextoBotaoNao = "Agora Nao",

    [Parameter(Mandatory = $false, HelpMessage = "Cor do header (hex)")]
    [string]$CorHeader = "#2196F3",

    [Parameter(Mandatory = $false, HelpMessage = "Cor do botao de confirmacao (hex)")]
    [string]$CorBotaoSim = "#4CAF50",

    [Parameter(Mandatory = $false, HelpMessage = "Codigo Unicode do icone do header")]
    [string]$IconeHeader = "&#x1F512;",

    [Parameter(Mandatory = $false, HelpMessage = "Se deve executar logoff ao confirmar")]
    [switch]$NaoExecutarLogoff,

    [Parameter(Mandatory = $false, HelpMessage = "Segundos de espera antes do logoff")]
    [int]$DelayLogoff = 3
)

$ErrorActionPreference = "Stop"

try {
    # Importar o modulo
    $CaminhoModulo = Join-Path $PSScriptRoot "PopupPersonalizado.psm1"

    if (-not (Test-Path $CaminhoModulo)) {
        throw "Modulo PopupPersonalizado.psm1 nao encontrado em: $CaminhoModulo"
    }

    Import-Module $CaminhoModulo -Force

    # Chamar a funcao
    $executarLogoff = -not $NaoExecutarLogoff.IsPresent

    $confirmou = Show-PopupPersonalizado `
        -Titulo $Titulo `
        -Mensagem $Mensagem `
        -Subtexto $Subtexto `
        -TextoBotaoSim $TextoBotaoSim `
        -TextoBotaoNao $TextoBotaoNao `
        -CorHeader $CorHeader `
        -CorBotaoSim $CorBotaoSim `
        -IconeHeader $IconeHeader `
        -ExecutarLogoff $executarLogoff `
        -DelayLogoff $DelayLogoff `
        -Verbose

    # Informar resultado
    if ($confirmou) {
        if ($executarLogoff) {
            Write-Host "Usuario confirmou - logoff sera executado" -ForegroundColor Green
        } else {
            Write-Host "Usuario confirmou (logoff nao sera executado)" -ForegroundColor Green
        }
        exit 0
    } else {
        Write-Host "Usuario cancelou" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Error "Erro ao exibir popup personalizado: $($_.Exception.Message)"
    exit 2
}