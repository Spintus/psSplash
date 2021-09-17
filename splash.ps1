<#
    .SYNOPSIS
        Display ASCII art in a scrolling banner.

    .DESCRIPTION
        Takes an array of lines and populates the host with a scrolling animation of the
        lines with some parameters for the animation and host window.

        This script uses .NET (WriteLine) calls to fire the console writing code. Lines
        are cleared for the next animation frame via SetCursorPosition and Write.

    .PARAMETER Splash
        The "image" (array of strings) to be animated.

    .PARAMETER BufferPref
        This int refers to the *minimum* desired buffer of empty space which is scrolled
        through after the end of the data in the Splash param. This buffer is the space
        between the trailing (right) edge of the left-most image and the leading (left)
        edge of the image to its right which is scrolling into frame.

        The buffer is set to whichever of these two values is greater:
            • width of image + BufferPref
            • width of console window

        Default: 10

    .PARAMETER FrameDelay
        This int refers to the desired time in milliseconds between animation frames.

        Default: 100

    .PARAMETER LoopDelay
        This int refers to the desired time in milliseconds between scrolling animations.

        Default: 2000

    .PARAMETER HostWidth
        This int refers to the desired width in characters to resize the host window to.
        This parameter will adjust the behavior of the BufferPref parameter similarly to
        how manually adjusting the host window size will change the buffer behavior.

        Default: 100

    .PARAMETER HostHeight
        This int refers to the desired height in characters to resize the host window to.
        Recommended to keep this a few lines greater than the height of your input Splash.

        Defaults to height of input SplashTxt + 2.

    .PARAMETER DisableQuickEdit
        Setting this flag will disable the default host's Quick-Edit mode, preventing
        pausing the animation when clicking inside the window while running.

    .PARAMETER AlwaysOnTop
        Setting this flag will cause the host window to stay on top of focused windows.

    .INPUTS
        System.String
        System.Int32

        You can pipe an array of strings splash.ps1.

    .OUTPUTS
        None.

    .EXAMPLE
        > & ...\splash.ps1..ps1 -Splash (gc '.\Quazar.txt') -BufferPref
        10 -FrameDelay 125

        Call script and provide contents of 'Quazar.txt' as the input to be animated.
        -BufferPref overrides the default minimum buffer size, putting at least (10)
        columns of blank space between the animated text blocks. -FrameDelay 125 overrides
        the default display timing per frame.

    .LINK
        https://docs.microsoft.com/en-us/dotnet/api/system.console.writeline?view=net-5.0
#>

[CmdletBinding()]
param
(
    [Parameter(Position = 0, ValueFromPipeline)]
    [string[]] $Splash           = @('"ROFL:ROFL:ROFL:ROFL"'
                                     '         _^___       '
                                     ' L    __/   [] \     '
                                     'LOL===__        \    '
                                     ' L      \________]   '
                                     '         I   I       '
                                     '        --------/    '),
    [int]      $BufferPref       = 10,
    [int]      $FrameDelay       = 100,
    [int]      $LoopDelay        = 2000,
    [int]      $HostWidth        = 100,
    [int]      $HostHeight,
    [switch]   $DisableQuickEdit,
    [switch]   $AlwaysOnTop
)

#requires -Version 5.1
Microsoft.PowerShell.Core\Set-StrictMode -Version 3.0

if ($DisableQuickEdit)
{
    # Prevent user interaction with splash window.
    . $PSScriptRoot\DisableQuickEdit.ps1
    [System.Console]::CursorVisible = $false
}

if ($AlwaysOnTop)
{
    # Set splash window always on top.
    . $PSScriptRoot\AlwaysOnTop.ps1
}

# Get data from splash.
$splashWidth = $splashHeight = 0
foreach ($line in $Splash)
{
    $splashWidth = [System.Math]::Max($splashWidth, $line.Length)
    $splashHeight++
}

# Configure host window/buffer size.
if (-not $HostWidth) {$HostWidth = $host.UI.RawUI.WindowSize.Width}
if (-not $HostHeight) {$HostHeight = $splashHeight + 2}

$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($HostWidth, 3000) # Arbitrary large height
$host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($HostWidth, $HostHeight)
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($HostWidth, $HostHeight)

# Set initial buffer size from host window and splash width.
$buffer = [System.Math]::Max($BufferPref, $HostWidth - $splashWidth)

# Animation loop.
:Main while ($true)
{
    # Scrolling animation.
    :Scroll for ($i = 0; $i -lt $splashWidth + $buffer; $i++)
    {
        # Set buffer size and output height.
        $HostWidth = $host.UI.RawUI.WindowSize.Width
        $buffer = [System.Math]::Max($BufferPref, $HostWidth - $splashWidth)
        $outHeight = [System.Math]::Min($splashHeight, $host.UI.RawUI.WindowSize.Height)

        # Print frame line by line.
        :Frame for ($j = 0; $j -lt $outHeight; $j++)
        {
            # Get line of txt and add buffer.
            $bufferedLine = [string]::concat($Splash[$j], [string]::Empty.PadRight($buffer, ' '))

            # Pad line to ensure uniform width.
            $paddedLine = $bufferedLine.PadRight($splashWidth + $buffer, ' ')
            $outLine = $paddedLine.Substring($i)

            # Pad or trim line to match console width.
            while ($outLine.Length -le $HostWidth)
            {
                $outLine = [string]::concat($outLine, $paddedLine)
            }
            if ($outLine.Length -gt $HostWidth)
            {
                $outLine = $outLine.Substring(0, $HostWidth)
            }

            [System.Console]::WriteLine($outLine)
        }

        Start-Sleep -Milliseconds $FrameDelay

        if ($i -lt $splashWidth + $buffer - 1)
        {
            # Clear previous lines to remove current rendered frame.
            $currentLine = $host.UI.RawUI.CursorPosition.Y
            :Clear for ($j = 0; $j -le $outHeight + 1; $j++)
            {
                [System.Console]::SetCursorPosition(0, ($currentLine - $j))
                [System.Console]::Write("{0, -$HostWidth}" -f ' ')
            }
        }

        # Re-hide cursor if host window has been resized.
        [System.Console]::CursorVisible = $false
    }

    Start-Sleep -Milliseconds $LoopDelay

    # Clear previous lines to remove current rendered frame.
    $currentLine = $host.UI.RawUI.CursorPosition.Y
    :Clear for ($i = 0; $i -le $outHeight + 1; $i++)
    {
        [System.Console]::SetCursorPosition(0, ($currentLine - $i))
        [System.Console]::Write("{0, -$HostWidth}" -f ' ')
    }
}
