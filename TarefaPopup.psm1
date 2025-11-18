function Show-PopupComoUsuario {
    <#
    .SYNOPSIS
    Cria tarefa temporaria para exibir popup no contexto do usuario logado

    .DESCRIPTION
    Quando rodando como SYSTEM (sessao 0 sem UI), esta funcao cria uma tarefa
    agendada temporaria que executa no contexto do usuario logado, permitindo
    que popups sejam exibidos corretamente.

    .PARAMETER ScriptPopup
    Caminho completo do script .ps1 que exibe o popup

    .PARAMETER ArgumentosPopup
    Argumentos adicionais a passar para o script do popup (opcional)

    .PARAMETER NomeUsuario
    Usuario especifico para executar o popup. Se nao especificado, descobre automaticamente.

    .PARAMETER AguardarSegundos
    Tempo em segundos para aguardar apos executar a tarefa (padrao: 3)

    .PARAMETER ManterTarefa
    Se $true, nao remove a tarefa apos execucao (padrao: $false)

    .EXAMPLE
    Show-PopupComoUsuario -ScriptPopup "C:\scripts\meu-popup.ps1"

    .EXAMPLE
    Show-PopupComoUsuario -ScriptPopup "C:\scripts\popup.ps1" -ArgumentosPopup "-Timeout 60" -AguardarSegundos 5

    .OUTPUTS
    Retorna $true se popup foi executado com sucesso, $false caso contrario
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPopup,

        [Parameter(Mandatory = $false)]
        [string]$ArgumentosPopup = "",

        [Parameter(Mandatory = $false)]
        [string]$NomeUsuario = "",

        [Parameter(Mandatory = $false)]
        [int]$AguardarSegundos = 3,

        [Parameter(Mandatory = $false)]
        [switch]$ManterTarefa
    )

    # Verificar se script existe
    if (-not (Test-Path $ScriptPopup)) {
        Write-Error "Script nao encontrado: $ScriptPopup"
        return $false
    }

    # Verificar se esta rodando como SYSTEM
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $isSystem = $currentUser.IsSystem

    # Se NAO for SYSTEM, executar diretamente
    if (-not $isSystem) {
        Write-Verbose "NAO e SYSTEM - executando popup diretamente..."
        try {
            if ($ArgumentosPopup) {
                # Usar Invoke-Expression para processar argumentos corretamente
                $comando = "& `"$ScriptPopup`" $ArgumentosPopup"
                Invoke-Expression $comando
            } else {
                & $ScriptPopup
            }
            Write-Verbose "Popup executado com sucesso"
            return $true
        } catch {
            Write-Error "Erro ao executar popup: $_"
            return $false
        }
    }

    # Rodando como SYSTEM - precisa criar tarefa no contexto do usuario
    Write-Verbose "Rodando como SYSTEM - criando tarefa no contexto do usuario..."

    # Descobrir usuario logado
    $usuarioReal = $null

    if ($NomeUsuario) {
        $usuarioReal = $NomeUsuario
        Write-Verbose "Usuario especificado: $usuarioReal"
    } else {
        Write-Verbose "Descobrindo usuario logado automaticamente..."

        # Metodo 1: Win32_ComputerSystem (mais rapido e confiavel)
        try {
            $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
            if ($computerSystem -and $computerSystem.UserName) {
                $usuarioCompleto = $computerSystem.UserName
                if ($usuarioCompleto -match '\\') {
                    $usuarioReal = $usuarioCompleto.Split('\')[1]
                    Write-Verbose "Usuario encontrado via Win32_ComputerSystem: $usuarioReal"
                }
            }
        } catch {
            Write-Verbose "Erro ao usar Win32_ComputerSystem: $_"
        }

        # Metodo 2: Explorer.exe owner (fallback)
        if (-not $usuarioReal) {
            try {
                $explorerProcess = Get-CimInstance -ClassName Win32_Process -Filter "Name='explorer.exe'" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($explorerProcess) {
                    $owner = Invoke-CimMethod -InputObject $explorerProcess -MethodName GetOwner
                    if ($owner -and $owner.User) {
                        $usuarioReal = $owner.User
                        Write-Verbose "Usuario encontrado via Explorer.exe: $usuarioReal"
                    }
                }
            } catch {
                Write-Verbose "Erro ao usar Explorer.exe: $_"
            }
        }

        # Metodo 3: Win32_LogonSession (ultimo recurso)
        if (-not $usuarioReal) {
            try {
                $logonSession = Get-CimInstance -ClassName Win32_LogonSession -Filter "LogonType=2" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($logonSession) {
                    $loggedOnUser = Get-CimAssociatedInstance -InputObject $logonSession -ResultClassName Win32_UserAccount -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($loggedOnUser) {
                        $usuarioReal = $loggedOnUser.Name
                        Write-Verbose "Usuario encontrado via Win32_LogonSession: $usuarioReal"
                    }
                }
            } catch {
                Write-Verbose "Erro ao usar Win32_LogonSession: $_"
            }
        }
    }

    # Validar se encontrou usuario
    if (-not $usuarioReal) {
        Write-Error "Nenhum usuario logado encontrado para mostrar popup"
        return $false
    }

    # Criar tarefa temporaria
    Write-Verbose "Criando tarefa temporaria para usuario '$usuarioReal'..."

    $taskName = "PopupTemp_$(Get-Date -Format 'yyyyMMddHHmmss')"

    # Construir argumentos
    $argumentosCompletos = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPopup`""
    if ($ArgumentosPopup) {
        $argumentosCompletos += " $ArgumentosPopup"
    }

    try {
        # Criar acao
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $argumentosCompletos

        # Criar principal (usuario logado)
        $principal = New-ScheduledTaskPrincipal -UserId $usuarioReal -RunLevel Highest

        # Registrar tarefa
        Register-ScheduledTask -TaskName $taskName `
            -Action $action `
            -Principal $principal `
            -Force | Out-Null

        Write-Verbose "Tarefa criada: $taskName"

        # Executar tarefa
        Start-ScheduledTask -TaskName $taskName
        Write-Verbose "Tarefa executada"

        # Aguardar
        if ($AguardarSegundos -gt 0) {
            Write-Verbose "Aguardando $AguardarSegundos segundos..."
            Start-Sleep -Seconds $AguardarSegundos
        }

        # Remover tarefa (se solicitado)
        if (-not $ManterTarefa) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
            Write-Verbose "Tarefa removida"
        }

        return $true

    } catch {
        Write-Error "Erro ao criar/executar tarefa: $_"
        return $false
    }
}

Export-ModuleMember -Function Show-PopupComoUsuario
