function Register-PowerShellParaNotificacoes {
    [CmdletBinding()]
    param()
    
    try {
        # Verificar se podemos registrar o PowerShell no registro para notificaï¿½ï¿½es
        $caminhoRegistro = "HKCU:\SOFTWARE\Classes\AppUserModelId"
        $idAplicativo = "PowerShell.Notificacoes"
        $caminhoAplicativo = "$caminhoRegistro\$idAplicativo"
        
        if (-not (Test-Path $caminhoRegistro)) {
            New-Item -Path $caminhoRegistro -Force | Out-Null
        }
        
        if (-not (Test-Path $caminhoAplicativo)) {
            New-Item -Path $caminhoAplicativo -Force | Out-Null
            # Se for mudar o -Value do próximo comando tem que rodar o clear-registration.ps1 e reiniciar o computador
            Set-ItemProperty -Path $caminhoAplicativo -Name "DisplayName" -Value "Notificações PowerShell"
            Set-ItemProperty -Path $caminhoAplicativo -Name "IconUri" -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            Write-Verbose "PowerShell registrado para notificaï¿½ï¿½es"
            return $idAplicativo
        }
        
        return $idAplicativo
    }
    catch {
        Write-Verbose "Nï¿½o foi possï¿½vel registrar o PowerShell para notificaï¿½ï¿½es: $($_.Exception.Message)"
        return $null
    }
}

function Show-NotificacaoWindows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Mensagem,
        
        [Parameter(Mandatory = $false)]
        [string]$Titulo = "Notificaï¿½ï¿½o",
        
        [Parameter(Mandatory = $false)]
        [switch]$UsarFallback,
        
        [Parameter(Mandatory = $false)]
        [switch]$Persistente
    )
    
    # Primeiro tenta o mï¿½todo de notificaï¿½ï¿½o Toast moderna
    if (-not $UsarFallback) {
        try {
            Write-Verbose "Tentando notificaï¿½ï¿½o toast moderna..."
            
            # Verificar se as notificaï¿½ï¿½es estï¿½o habilitadas
            $configuracaoNotificacao = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -ErrorAction SilentlyContinue
            if ($configuracaoNotificacao -and $configuracaoNotificacao.ToastEnabled -eq 0) {
                Write-Warning "Notificaï¿½ï¿½es do Windows estï¿½o desabilitadas nas configuraï¿½ï¿½es do sistema"
            }
            
            Add-Type -AssemblyName System.Windows.Forms
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

            # Primeiro tenta registrar o PowerShell para notificaï¿½ï¿½es
            $idAplicativoRegistrado = Register-PowerShellParaNotificacoes
            
            # Tenta mï¿½ltiplos IDs de aplicativo em ordem de preferï¿½ncia
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
            
            # Criar templates diferentes para notificaï¿½ï¿½es persistentes vs normais
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

            # Tenta cada ID de aplicativo atï¿½ que um funcione
            foreach ($idAplicativo in $idsAplicativo) {
                try {
                    Write-Verbose "Tentando ID do aplicativo: $idAplicativo"
                    
                    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
                    $xml.LoadXml($template)
                    
                    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
                    
                    # Sï¿½ define tempo de expiraï¿½ï¿½o para notificaï¿½ï¿½es nï¿½o persistentes
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
                Write-Verbose "Notificaï¿½ï¿½o toast enviada com sucesso com ID do aplicativo '$idAplicativoSucesso': $Titulo - $Mensagem"
                return $true
            } else {
                throw "Todos os IDs de aplicativo falharam para notificaï¿½ï¿½o toast"
            }
        }
        catch {
            Write-Warning "Notificaï¿½ï¿½o toast falhou: $($_.Exception.Message). Tentando mï¿½todo fallback..."
        }
    }
    
    # Fallback: Usar Windows Forms NotifyIcon (balï¿½o da bandeja do sistema)
    try {
        Write-Verbose "Usando fallback de notificaï¿½ï¿½o balï¿½o da bandeja do sistema..."
        
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $icone = New-Object System.Windows.Forms.NotifyIcon
        $icone.Icon = [System.Drawing.SystemIcons]::Information
        $icone.Visible = $true
        
        # Notificaï¿½ï¿½es balï¿½o nï¿½o podem ser verdadeiramente persistentes, mas podemos fazï¿½-las durar mais
        $duracao = if ($Persistente) { 30000 } else { 5000 }  # 30 segundos vs 5 segundos
        $icone.ShowBalloonTip($duracao, $Titulo, $Mensagem, [System.Windows.Forms.ToolTipIcon]::Info)
        
        # Limpar apï¿½s um tempo
        Start-Sleep -Seconds 1
        $icone.Dispose()
        
        if ($Persistente) {
            Write-Verbose "Notificaï¿½ï¿½o balï¿½o de longa duraï¿½ï¿½o enviada (30s): $Titulo - $Mensagem"
        } else {
            Write-Verbose "Notificaï¿½ï¿½o balï¿½o enviada com sucesso: $Titulo - $Mensagem"
        }
        return $true
    }
    catch {
        Write-Error "Todos os mï¿½todos de notificaï¿½ï¿½o falharam. ï¿½ltimo erro: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Show-NotificacaoWindows, Register-PowerShellParaNotificacoes