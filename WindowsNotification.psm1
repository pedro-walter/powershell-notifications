function Registrar-PowerShellParaNotificacoes {
    [CmdletBinding()]
    param()
    
    try {
        # Verificar se podemos registrar o PowerShell no registro para notificações
        $caminhoRegistro = "HKCU:\SOFTWARE\Classes\AppUserModelId"
        $idAplicativo = "PowerShell.Notificacoes"
        $caminhoAplicativo = "$caminhoRegistro\$idAplicativo"
        
        if (-not (Test-Path $caminhoRegistro)) {
            New-Item -Path $caminhoRegistro -Force | Out-Null
        }
        
        if (-not (Test-Path $caminhoAplicativo)) {
            New-Item -Path $caminhoAplicativo -Force | Out-Null
            Set-ItemProperty -Path $caminhoAplicativo -Name "DisplayName" -Value "Notificações PowerShell"
            Set-ItemProperty -Path $caminhoAplicativo -Name "IconUri" -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            Write-Verbose "PowerShell registrado para notificações"
            return $idAplicativo
        }
        
        return $idAplicativo
    }
    catch {
        Write-Verbose "Não foi possível registrar o PowerShell para notificações: $($_.Exception.Message)"
        return $null
    }
}

function Exibir-NotificacaoWindows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Mensagem,
        
        [Parameter(Mandatory = $false)]
        [string]$Titulo = "Notificação",
        
        [Parameter(Mandatory = $false)]
        [switch]$UsarFallback,
        
        [Parameter(Mandatory = $false)]
        [switch]$Persistente
    )
    
    # Primeiro tenta o método de notificação Toast moderna
    if (-not $UsarFallback) {
        try {
            Write-Verbose "Tentando notificação toast moderna..."
            
            # Verificar se as notificações estão habilitadas
            $configuracaoNotificacao = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -ErrorAction SilentlyContinue
            if ($configuracaoNotificacao -and $configuracaoNotificacao.ToastEnabled -eq 0) {
                Write-Warning "Notificações do Windows estão desabilitadas nas configurações do sistema"
            }
            
            Add-Type -AssemblyName System.Windows.Forms
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

            # Primeiro tenta registrar o PowerShell para notificações
            $idAplicativoRegistrado = Registrar-PowerShellParaNotificacoes
            
            # Tenta múltiplos IDs de aplicativo em ordem de preferência
            $idsAplicativo = @()
            if ($idAplicativoRegistrado) { $idsAplicativo += $idAplicativoRegistrado }
            $idsAplicativo += @(
                "Microsoft.Windows.PowerShell",
                "Windows.PowerShell", 
                "PowerShell",
                "Microsoft.WindowsTerminal_8wekyb3d8bbwe!App",
                "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
            )
            
            $idAplicativoSucesso = $null
            
            # Criar templates diferentes para notificações persistentes vs normais
            if ($Persistente) {
                $template = @"
<toast scenario="reminder" activationType="foreground">
    <visual>
        <binding template="ToastGeneric">
            <text>$([System.Security.SecurityElement]::Escape($Titulo))</text>
            <text>$([System.Security.SecurityElement]::Escape($Mensagem))</text>
        </binding>
    </visual>
    <actions>
        <action activationType="system" arguments="dismiss" content="Fechar"/>
    </actions>
    <audio silent="false"/>
</toast>
"@
            } else {
                $template = @"
<toast activationType="foreground">
    <visual>
        <binding template="ToastGeneric">
            <text>$([System.Security.SecurityElement]::Escape($Titulo))</text>
            <text>$([System.Security.SecurityElement]::Escape($Mensagem))</text>
        </binding>
    </visual>
    <audio silent="false"/>
</toast>
"@
            }

            # Tenta cada ID de aplicativo até que um funcione
            foreach ($idAplicativo in $idsAplicativo) {
                try {
                    Write-Verbose "Tentando ID do aplicativo: $idAplicativo"
                    
                    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
                    $xml.LoadXml($template)
                    
                    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
                    
                    # Só define tempo de expiração para notificações não persistentes
                    if (-not $Persistente) {
                        $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(5)
                    }
                    
                    $notificador = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($idAplicativo)
                    $notificador.Show($toast)
                    
                    $idAplicativoSucesso = $idAplicativo
                    break
                }
                catch {
                    Write-Verbose "ID do aplicativo $idAplicativo falhou: $($_.Exception.Message)"
                    continue
                }
            }
            
            if ($idAplicativoSucesso) {
                # Aguarda um momento para ver se realmente aparece
                Start-Sleep -Milliseconds 500
                Write-Verbose "Notificação toast enviada com sucesso com ID do aplicativo '$idAplicativoSucesso': $Titulo - $Mensagem"
                return $true
            } else {
                throw "Todos os IDs de aplicativo falharam para notificação toast"
            }
        }
        catch {
            Write-Warning "Notificação toast falhou: $($_.Exception.Message). Tentando método fallback..."
        }
    }
    
    # Fallback: Usar Windows Forms NotifyIcon (balão da bandeja do sistema)
    try {
        Write-Verbose "Usando fallback de notificação balão da bandeja do sistema..."
        
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $icone = New-Object System.Windows.Forms.NotifyIcon
        $icone.Icon = [System.Drawing.SystemIcons]::Information
        $icone.Visible = $true
        
        # Notificações balão não podem ser verdadeiramente persistentes, mas podemos fazê-las durar mais
        $duracao = if ($Persistente) { 30000 } else { 5000 }  # 30 segundos vs 5 segundos
        $icone.ShowBalloonTip($duracao, $Titulo, $Mensagem, [System.Windows.Forms.ToolTipIcon]::Info)
        
        # Limpar após um tempo
        Start-Sleep -Seconds 1
        $icone.Dispose()
        
        if ($Persistente) {
            Write-Verbose "Notificação balão de longa duração enviada (30s): $Titulo - $Mensagem"
        } else {
            Write-Verbose "Notificação balão enviada com sucesso: $Titulo - $Mensagem"
        }
        return $true
    }
    catch {
        Write-Error "Todos os métodos de notificação falharam. Último erro: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Exibir-NotificacaoWindows, Registrar-PowerShellParaNotificacoes