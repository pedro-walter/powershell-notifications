function Show-PopupLogoff {
    <#
    .SYNOPSIS
    Exibe popup modal perguntando se usuario deseja fazer logoff do Windows.

    .DESCRIPTION
    Mostra uma caixa de dialogo com botoes Sim/Nao. Se o usuario clicar em Sim,
    faz logoff automaticamente do Windows. Se clicar em Nao, cancela a operacao.

    .PARAMETER Titulo
    Titulo da janela do popup

    .PARAMETER Mensagem
    Mensagem a ser exibida no popup

    .PARAMETER Timeout
    Tempo em segundos ate fechar automaticamente e fazer logoff. 0 = sem timeout.

    .PARAMETER DelayLogoff
    Tempo de espera em segundos antes de executar o logoff apos usuario confirmar.

    .EXAMPLE
    Show-PopupLogoff
    Exibe popup com mensagem padrao

    .EXAMPLE
    Show-PopupLogoff -Titulo "Sessao Expirada" -Mensagem "Sua sessao expirou. Fazer logoff?"
    Exibe popup com mensagem personalizada

    .EXAMPLE
    Show-PopupLogoff -Timeout 60
    Exibe popup que faz logoff automaticamente apos 60 segundos sem resposta

    .OUTPUTS
    Retorna $true se logoff foi executado, $false se foi cancelado
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Titulo = "Acesso de Administrador Concedido",

        [Parameter(Mandatory = $false)]
        [string]$Mensagem = "Seu acesso de administrador foi concedido.`n`nPara aplicar as permissoes, e necessario fazer logoff.`n`nDeseja fazer logoff agora?",

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 0,

        [Parameter(Mandatory = $false)]
        [int]$DelayLogoff = 3
    )

    try {
        # Criar o objeto WScript.Shell
        $wshell = New-Object -ComObject WScript.Shell

        # Definir tipo de popup
        # 4 = Sim/Nao, 32 = Icone de pergunta, 256 = Segundo botao padrao (Nao), 4096 = System Modal (sempre no topo)
        $tipo = 4 + 32 + 256 + 4096

        Write-Verbose "Exibindo popup de logoff..."

        # Exibir popup e capturar resposta
        $resposta = $wshell.Popup($Mensagem, $Timeout, $Titulo, $tipo)

        # Processar resposta
        # 6 = Sim, 7 = Nao, -1 = Timeout
        $fazerLogoff = $false

        switch ($resposta) {
            6 {
                Write-Verbose "Usuario clicou SIM - fazendo logoff..."
                $fazerLogoff = $true
            }
            7 {
                Write-Verbose "Usuario clicou NAO - logoff cancelado"
                $fazerLogoff = $false
            }
            -1 {
                Write-Verbose "Timeout - fazendo logoff automaticamente..."
                $fazerLogoff = $true
            }
            default {
                Write-Warning "Resposta inesperada: $resposta"
                $fazerLogoff = $false
            }
        }

        # Fazer logoff se usuario confirmou
        if ($fazerLogoff) {
            Write-Verbose "Executando logoff em $DelayLogoff segundos..."
            Start-Sleep -Seconds $DelayLogoff

            # Executar logoff do Windows
            shutdown /l /f

            Write-Verbose "Comando de logoff enviado!"
        }

        return $fazerLogoff
    }
    catch {
        Write-Error "Erro ao executar popup de logoff: $_"
        return $false
    }
    finally {
        # Limpar COM object
        if ($wshell) {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wshell) | Out-Null
        }
    }
}

Export-ModuleMember -Function Show-PopupLogoff