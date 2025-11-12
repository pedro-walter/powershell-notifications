function Register-PowerShellForNotifications {
    [CmdletBinding()]
    param()
    
    try {
        # Check if we can register PowerShell in the registry for notifications
        $regPath = "HKCU:\SOFTWARE\Classes\AppUserModelId"
        $appId = "PowerShell.Notifications"
        $appPath = "$regPath\$appId"
        
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        if (-not (Test-Path $appPath)) {
            New-Item -Path $appPath -Force | Out-Null
            Set-ItemProperty -Path $appPath -Name "DisplayName" -Value "PowerShell Notifications"
            Set-ItemProperty -Path $appPath -Name "IconUri" -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            Write-Verbose "Registered PowerShell for notifications"
            return $appId
        }
        
        return $appId
    }
    catch {
        Write-Verbose "Could not register PowerShell for notifications: $($_.Exception.Message)"
        return $null
    }
}

function Show-WindowsNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Notification",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseFallback,
        
        [Parameter(Mandatory = $false)]
        [switch]$Sticky
    )
    
    # First try the modern Toast notification approach
    if (-not $UseFallback) {
        try {
            Write-Verbose "Attempting modern toast notification..."
            
            # Check if notifications are enabled
            $notificationSetting = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -ErrorAction SilentlyContinue
            if ($notificationSetting -and $notificationSetting.ToastEnabled -eq 0) {
                Write-Warning "Windows notifications are disabled in system settings"
            }
            
            Add-Type -AssemblyName System.Windows.Forms
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

            # Try to register PowerShell for notifications first
            $registeredAppId = Register-PowerShellForNotifications
            
            # Try multiple application IDs in order of preference
            $appIds = @()
            if ($registeredAppId) { $appIds += $registeredAppId }
            $appIds += @(
                "Microsoft.Windows.PowerShell",
                "Windows.PowerShell", 
                "PowerShell",
                "Microsoft.WindowsTerminal_8wekyb3d8bbwe!App",
                "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
            )
            
            $successfulAppId = $null
            
            # Create different templates for sticky vs normal notifications
            if ($Sticky) {
                $template = @"
<toast scenario="reminder" activationType="foreground">
    <visual>
        <binding template="ToastGeneric">
            <text>$([System.Security.SecurityElement]::Escape($Title))</text>
            <text>$([System.Security.SecurityElement]::Escape($Message))</text>
        </binding>
    </visual>
    <actions>
        <action activationType="system" arguments="dismiss" content="Close"/>
    </actions>
    <audio silent="false"/>
</toast>
"@
            } else {
                $template = @"
<toast activationType="foreground">
    <visual>
        <binding template="ToastGeneric">
            <text>$([System.Security.SecurityElement]::Escape($Title))</text>
            <text>$([System.Security.SecurityElement]::Escape($Message))</text>
        </binding>
    </visual>
    <audio silent="false"/>
</toast>
"@
            }

            # Try each app ID until one works
            foreach ($appId in $appIds) {
                try {
                    Write-Verbose "Trying app ID: $appId"
                    
                    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
                    $xml.LoadXml($template)
                    
                    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
                    
                    # Only set expiration time for non-sticky notifications
                    if (-not $Sticky) {
                        $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(5)
                    }
                    
                    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
                    $notifier.Show($toast)
                    
                    $successfulAppId = $appId
                    break
                }
                catch {
                    Write-Verbose "App ID $appId failed: $($_.Exception.Message)"
                    continue
                }
            }
            
            if ($successfulAppId) {
                # Wait a moment to see if it actually appears
                Start-Sleep -Milliseconds 500
                Write-Verbose "Toast notification sent successfully with app ID '$successfulAppId': $Title - $Message"
                return $true
            } else {
                throw "All app IDs failed for toast notification"
            }
        }
        catch {
            Write-Warning "Toast notification failed: $($_.Exception.Message). Trying fallback method..."
        }
    }
    
    # Fallback: Use Windows Forms NotifyIcon (system tray balloon)
    try {
        Write-Verbose "Using system tray balloon notification fallback..."
        
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $icon = New-Object System.Windows.Forms.NotifyIcon
        $icon.Icon = [System.Drawing.SystemIcons]::Information
        $icon.Visible = $true
        
        # Balloon notifications can't be truly sticky, but we can make them last longer
        $duration = if ($Sticky) { 30000 } else { 5000 }  # 30 seconds vs 5 seconds
        $icon.ShowBalloonTip($duration, $Title, $Message, [System.Windows.Forms.ToolTipIcon]::Info)
        
        # Clean up after a delay
        Start-Sleep -Seconds 1
        $icon.Dispose()
        
        if ($Sticky) {
            Write-Verbose "Long-duration balloon notification sent (30s): $Title - $Message"
        } else {
            Write-Verbose "Balloon notification sent successfully: $Title - $Message"
        }
        return $true
    }
    catch {
        Write-Error "All notification methods failed. Last error: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Show-WindowsNotification, Register-PowerShellForNotifications