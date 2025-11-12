[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The message to display in the notification")]
    [string]$Message,
    
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "The title of the notification")]
    [string]$Title = "Notification",
    
    [Parameter(Mandatory = $false, HelpMessage = "Use fallback system tray balloon instead of toast notification")]
    [switch]$UseFallback,
    
    [Parameter(Mandatory = $false, HelpMessage = "Make the notification sticky (only goes away when manually dismissed)")]
    [switch]$Sticky
)

$ErrorActionPreference = "Stop"

try {
    $ModulePath = Join-Path $PSScriptRoot "WindowsNotification.psm1"
    
    if (-not (Test-Path $ModulePath)) {
        throw "WindowsNotification module not found at: $ModulePath"
    }
    
    Import-Module $ModulePath -Force
    
    $result = Show-WindowsNotification -Message $Message -Title $Title -UseFallback:$UseFallback -Sticky:$Sticky
    
    if ($result) {
        Write-Host "Notification sent successfully!" -ForegroundColor Green
    } else {
        Write-Host "Notification failed to send." -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Error "Error sending notification: $($_.Exception.Message)"
    exit 1
}