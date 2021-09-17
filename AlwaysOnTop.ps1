# Quick p/invoke for method.
$type = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool SetWindowPos(
    IntPtr hWnd,
    IntPtr hWndInsertAfter,
    int X,
    int Y,
    int cx,
    int cy,
    uint uFlags);
'@ -Name SetWindowPosition -Namespace SetWindowPos -Using System.Text -PassThru

$handle = (Get-Process -id $Global:PID).MainWindowHandle
$alwaysOnTop = New-Object System.IntPtr -ArgumentList (-1)
$type::SetWindowPos($handle, $alwaysOnTop, 0, 0, 0, 0, 0x0003)
