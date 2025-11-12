Write-Host "=== Windows Notification Settings Diagnostics ===" -ForegroundColor Cyan

# Check global notification settings
Write-Host "`n1. Global Notification Settings:" -ForegroundColor Yellow
try {
    $toastEnabled = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -ErrorAction SilentlyContinue
    if ($toastEnabled) {
        if ($toastEnabled.ToastEnabled -eq 1) {
            Write-Host "   ✓ Toast notifications are ENABLED" -ForegroundColor Green
        } else {
            Write-Host "   ✗ Toast notifications are DISABLED" -ForegroundColor Red
        }
    } else {
        Write-Host "   ? Toast notification setting not found (may be enabled by default)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ Could not check toast notification settings" -ForegroundColor Red
}

# Check Focus Assist
Write-Host "`n2. Focus Assist Settings:" -ForegroundColor Yellow
try {
    $focusAssistPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount"
    $focusAssist = Get-ChildItem $focusAssistPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*windows.data.notifications.quiethours*" }
    if ($focusAssist) {
        Write-Host "   ? Focus Assist settings found - may be active" -ForegroundColor Yellow
    } else {
        Write-Host "   ✓ Focus Assist likely not blocking notifications" -ForegroundColor Green
    }
} catch {
    Write-Host "   ? Could not determine Focus Assist status" -ForegroundColor Yellow
}

# Check if PowerShell is registered for notifications
Write-Host "`n3. PowerShell Notification Registration:" -ForegroundColor Yellow
$regPath = "HKCU:\SOFTWARE\Classes\AppUserModelId\PowerShell.Notifications"
if (Test-Path $regPath) {
    Write-Host "   ✓ PowerShell is registered for notifications" -ForegroundColor Green
} else {
    Write-Host "   ✗ PowerShell is NOT registered for notifications" -ForegroundColor Red
    Write-Host "     Will attempt to register when running notifications" -ForegroundColor Gray
}

# Test Windows Runtime API availability
Write-Host "`n4. Windows Runtime API Test:" -ForegroundColor Yellow
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    Write-Host "   ✓ Windows Runtime notification APIs are available" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Windows Runtime notification APIs are NOT available" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check Windows version
Write-Host "`n5. Windows Version:" -ForegroundColor Yellow
$version = [Environment]::OSVersion.Version
if ($version.Major -ge 10) {
    Write-Host "   ✓ Windows 10/11 detected (supports toast notifications)" -ForegroundColor Green
} else {
    Write-Host "   ✗ Older Windows version detected (may not support toast notifications)" -ForegroundColor Red
}

Write-Host "`n=== Recommendations ===" -ForegroundColor Cyan
Write-Host "1. If toast notifications are disabled, enable them in Settings > System > Notifications" 
Write-Host "2. If Focus Assist is on, disable it or add PowerShell as an exception"
Write-Host "3. Try running the notification script - it will attempt to register PowerShell automatically"
Write-Host "4. If toast notifications still fail, use the -UseFallback parameter for reliable balloon notifications"