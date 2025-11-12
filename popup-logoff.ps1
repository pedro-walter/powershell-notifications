param (
    [string]$Titulo = "Acesso de Administrador Concedido",
    [string]$Mensagem = "Seu acesso de administrador foi concedido.`n`nPara aplicar as permissoes, e necessario fazer logoff.`n`nDeseja fazer logoff agora?",
    [int]$Timeout = 0  # 0 = sem timeout, ou numero de segundos
)

try {
    # Criar o objeto WScript.Shell
    $wshell = New-Object -ComObject WScript.Shell

    # Definir tipo de popup
    # 4 = Sim/Nao, 32 = Icone de pergunta, 4096 = System Modal (sempre no topo)
    $tipo = 4 + 32 + 4096

    Write-Host "Exibindo popup de logoff..." -ForegroundColor Cyan

    # Exibir popup e capturar resposta
    $resposta = $wshell.Popup($Mensagem, $Timeout, $Titulo, $tipo)

    # Processar resposta
    # 6 = Sim, 7 = Nao, -1 = Timeout
    switch ($resposta) {
        6 {
            Write-Host "Usuario clicou SIM - fazendo logoff..." -ForegroundColor Green
            $fazerLogoff = $true
        }
        7 {
            Write-Host "Usuario clicou NAO - logoff cancelado" -ForegroundColor Yellow
            $fazerLogoff = $false
        }
        -1 {
            Write-Host "Timeout - fazendo logoff automaticamente..." -ForegroundColor Yellow
            $fazerLogoff = $true
        }
        default {
            Write-Host "Resposta inesperada: $resposta" -ForegroundColor Red
            $fazerLogoff = $false
        }
    }

    # Fazer logoff se usuario confirmou
    if ($fazerLogoff) {
        Write-Host "Executando logoff em 3 segundos..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3

        # Executar logoff do Windows
        shutdown /l /f

        Write-Host "Comando de logoff enviado!" -ForegroundColor Green
    }
}
catch {
    Write-Error "Erro ao executar popup de logoff: $_"
}
finally {
    # Limpar COM object
    if ($wshell) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wshell) | Out-Null
    }
}