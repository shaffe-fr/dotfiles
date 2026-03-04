param([string]$target)

if (-not $target) { $target = Get-Location }
$resolved = Resolve-Path $target -ErrorAction SilentlyContinue
if ($resolved) { $target = $resolved.Path.TrimEnd('\') }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd, int cmd);
[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hwnd);
'@ -Name Win32 -Namespace Native

$shell = New-Object -ComObject Shell.Application
$before = $shell.Windows().Count

if ($before -eq 0) {
    Start-Process explorer.exe $target
    return
}

$all = Get-Process explorer | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -ne '' }
$exp = $all | Where-Object { -not [Native.Win32]::IsIconic($_.MainWindowHandle) } | Select-Object -First 1
if (-not $exp) { $exp = $all | Select-Object -First 1 }

$h = $exp.MainWindowHandle
[Native.Win32]::ShowWindow($h, 9) | Out-Null
[Native.Win32]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 150
[System.Windows.Forms.SendKeys]::SendWait('^t')
Start-Sleep -Milliseconds 300

$after = $shell.Windows().Count
if ($after -gt $before) {
    $shell.Windows().Item($after - 1).Navigate($target)
}
