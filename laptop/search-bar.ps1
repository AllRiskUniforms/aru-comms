# A Windows 98 style search box on Plato's RetroBar taskbar, in place of the Windows
# search bar that RetroBar hides. Type to see matches, then pick one with the arrow keys
# and Enter (or a click): a program from the Start menu, "Search files" (Explorer search
# of your user folder) or "Search the web". Drag the grip on its left to move it.
# It hides while the ARU 98 lock or anything full screen is in front.
# win98-desktop.ps1 starts it at sign-in; starting it again replaces the running copy.

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class Native {
  [StructLayout(LayoutKind.Sequential)]
  public struct RECT { public int Left, Top, Right, Bottom; }

  [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr hwnd, StringBuilder name, int max);
  [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hwnd, int cmd);

  // Shown above other windows without taking focus: SW_SHOWNOACTIVATE, then
  // HWND_TOPMOST with NOSIZE|NOMOVE|NOACTIVATE.
  public static void ShowOnTop(IntPtr hwnd) {
    ShowWindow(hwnd, 4);
    SetWindowPos(hwnd, new IntPtr(-1), 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0010);
  }

  public static void Hide(IntPtr hwnd) { ShowWindow(hwnd, 0); }

  // True when the front window covers the whole screen (a video, a game, the lock),
  // not counting the desktop itself, which is screen-sized too.
  public static bool FullScreenInFront(int width, int height) {
    IntPtr fg = GetForegroundWindow();
    if (fg == IntPtr.Zero) return false;
    StringBuilder cls = new StringBuilder(64);
    GetClassName(fg, cls, cls.Capacity);
    string name = cls.ToString();
    if (name == "Progman" || name == "WorkerW") return false;
    RECT r;
    return GetWindowRect(fg, out r) && r.Left <= 0 && r.Top <= 0 && r.Right >= width && r.Bottom >= height;
  }
}
'@

# One copy at a time, always the newest code.
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
  Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*search-bar.ps1*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

[Windows.Forms.Application]::VisualStyleState = 'NoneEnabled'  # classic 3D borders, like 98
$Settings = Join-Path $env:LOCALAPPDATA 'ARU98\search-bar.json'
$Face = [Drawing.Color]::FromArgb(192, 192, 192)
$Font = New-Object Drawing.Font('Tahoma', 8.25)

$Apps = @()
$AppsLoaded = [datetime]::MinValue
function Update-Apps {
  if (((Get-Date) - $script:AppsLoaded).TotalMinutes -ge 10) {
    $script:Apps = @(Get-StartApps)
    $script:AppsLoaded = Get-Date
  }
}

$bar = New-Object Windows.Forms.Form
$bar.FormBorderStyle = 'None'
$bar.ShowInTaskbar = $false
$bar.TopMost = $true
$bar.StartPosition = 'Manual'
$bar.BackColor = $Face
$bar.Font = $Font
$scale = if ($bar.DeviceDpi) { $bar.DeviceDpi / 96.0 } else { 1.0 }
function Px($n) { [int][Math]::Round($n * $scale) }

# The bar is a strip (grip, "Search" label, text box) along the taskbar. While there are
# matches, the form grows upward and the list fills the space above the strip.
$strip = New-Object Windows.Forms.Panel
$strip.Dock = 'Bottom'
$strip.BackColor = $Face

$grip = New-Object Windows.Forms.Panel
$grip.Cursor = 'SizeWE'
$grip.Add_Paint({
  param($s, $e)
  # A raised Windows 98 toolbar grip: white on the left, gray on the right.
  $h = $s.Height - 3
  $e.Graphics.DrawLine([Drawing.Pens]::White, 0, 2, 0, $h)
  $e.Graphics.DrawLine([Drawing.Pens]::White, 0, 2, 1, 2)
  $e.Graphics.DrawLine([Drawing.Pens]::Gray, 2, 2, 2, $h)
  $e.Graphics.DrawLine([Drawing.Pens]::Gray, 0, $h, 2, $h)
})

$label = New-Object Windows.Forms.Label
$label.Text = 'Search'
$label.AutoSize = $true
$label.BackColor = $Face

$box = New-Object Windows.Forms.TextBox
$box.BorderStyle = 'Fixed3D'

$list = New-Object Windows.Forms.ListBox
$list.Dock = 'Fill'
$list.BorderStyle = 'FixedSingle'
$list.IntegralHeight = $false

$strip.Controls.AddRange(@($grip, $label, $box))
$bar.Controls.Add($list)
$bar.Controls.Add($strip)

$script:StripTop = 0
$script:ListShown = $false
function Update-Layout {
  $screen = [Windows.Forms.Screen]::PrimaryScreen
  $top = $screen.WorkingArea.Bottom
  $height = $screen.Bounds.Bottom - $top
  if ($height -lt (Px 20)) { $height = Px 28; $top = $screen.Bounds.Bottom - $height }  # taskbar hidden or not at the bottom
  $stripHeight = $height - (Px 6)
  $width = Px 230
  $script:StripTop = $top + (Px 3)

  $strip.Height = $stripHeight
  $grip.SetBounds((Px 2), 0, (Px 3) + 1, $stripHeight)
  $label.Left = $grip.Right + (Px 4)
  $label.Top = [Math]::Max(0, [int](($stripHeight - $label.PreferredHeight) / 2))
  $box.Left = $label.Left + $label.PreferredWidth + (Px 2)
  $box.Width = $width - $box.Left - (Px 2)
  $box.Top = [Math]::Max(0, [int](($stripHeight - $box.Height) / 2))

  $x = $screen.Bounds.Right - $width - (Px 230)  # default: left of the tray and clock
  if (Test-Path $Settings) { try { $x = [int](Get-Content $Settings -Raw | ConvertFrom-Json).x } catch {} }
  $x = [Math]::Max(0, [Math]::Min($x, $screen.Bounds.Right - $width))
  $bar.SetBounds($x, $script:StripTop, $width, $stripHeight)
  $script:LayoutFor = $screen.WorkingArea
  Set-ListShown $script:ListShown
}

function Set-ListShown($show) {
  $script:ListShown = $show
  $listHeight = if ($show) { [Math]::Min($list.Items.Count, 10) * $list.ItemHeight + 4 } else { 0 }
  $bar.SetBounds($bar.Left, $script:StripTop - $listHeight, $bar.Width, $strip.Height + $listHeight)
}

$script:Choices = @()
function Update-List {
  $q = $box.Text.Trim()
  $script:Choices = @()
  if ($q) {
    Update-Apps
    $script:Choices += @($script:Apps |
      Where-Object { $_.Name.IndexOf($q, [StringComparison]::OrdinalIgnoreCase) -ge 0 } |
      Sort-Object @{ Expression = { -not $_.Name.StartsWith($q, [StringComparison]::OrdinalIgnoreCase) } }, Name |
      Select-Object -First 7 |
      ForEach-Object { [pscustomobject]@{ Text = $_.Name; Kind = 'app'; Value = $_.AppID } })
    $script:Choices += [pscustomobject]@{ Text = "Search files for `"$q`""; Kind = 'files'; Value = $q }
    $script:Choices += [pscustomobject]@{ Text = "Search the web for `"$q`""; Kind = 'web'; Value = $q }
  }
  $list.BeginUpdate()
  $list.Items.Clear()
  foreach ($c in $script:Choices) { [void]$list.Items.Add($c.Text) }
  $list.EndUpdate()
  if ($list.Items.Count) { $list.SelectedIndex = 0 }
  Set-ListShown ($list.Items.Count -gt 0)
}

function Invoke-Choice {
  if ($list.SelectedIndex -lt 0) { return }
  $c = $script:Choices[$list.SelectedIndex]
  $q = [uri]::EscapeDataString($c.Value)
  switch ($c.Kind) {
    'app'   { Start-Process "$env:WINDIR\explorer.exe" "shell:AppsFolder\$($c.Value)" }
    'files' { Start-Process "search-ms:query=$q&crumb=location:$([uri]::EscapeDataString($env:USERPROFILE))" }
    'web'   { Start-Process "https://www.google.com/search?q=$q" }
  }
  $box.Clear()
}

$box.Add_TextChanged({ Update-List })
$box.Add_KeyDown({
  param($s, $e)
  switch ($e.KeyCode) {
    'Down'   { if ($list.SelectedIndex -lt $list.Items.Count - 1) { $list.SelectedIndex = $list.SelectedIndex + 1 }; $e.Handled = $true }
    'Up'     { if ($list.SelectedIndex -gt 0) { $list.SelectedIndex = $list.SelectedIndex - 1 }; $e.Handled = $true }
    'Enter'  { Invoke-Choice; $e.SuppressKeyPress = $true }
    'Escape' { $box.Clear(); $e.SuppressKeyPress = $true }
  }
})
$list.Add_Click({ Invoke-Choice })
$bar.Add_Deactivate({ if ($script:ListShown) { $box.Clear() } })

# Drag the grip to slide the bar along the taskbar; where it's left is remembered.
$script:DragFrom = $null
$grip.Add_MouseDown({ param($s, $e) if ($e.Button -eq 'Left') { $script:DragFrom = [Windows.Forms.Cursor]::Position.X - $bar.Left } })
$grip.Add_MouseMove({
  if ($null -ne $script:DragFrom) {
    $right = [Windows.Forms.Screen]::PrimaryScreen.Bounds.Right - $bar.Width
    $bar.Left = [Math]::Max(0, [Math]::Min([Windows.Forms.Cursor]::Position.X - $script:DragFrom, $right))
  }
})
$grip.Add_MouseUp({
  $script:DragFrom = $null
  try { @{ x = $bar.Left } | ConvertTo-Json | Set-Content $Settings } catch {}
})

# Every 2 s: follow taskbar changes (RetroBar may start after this), stay on top, and
# keep out of the way of the lock screen and full-screen windows.
$script:Hidden = $false
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({
  try {
    $screen = [Windows.Forms.Screen]::PrimaryScreen
    if ($screen.WorkingArea -ne $script:LayoutFor) { Update-Layout }
    $lock = Get-Process msedge -ErrorAction SilentlyContinue | Where-Object MainWindowTitle -like 'ARU 98*'
    if ($lock -or [Native]::FullScreenInFront($screen.Bounds.Width, $screen.Bounds.Height)) {
      if (-not $script:Hidden) { $box.Clear(); [Native]::Hide($bar.Handle); $script:Hidden = $true }
    } else {
      [Native]::ShowOnTop($bar.Handle)
      $script:Hidden = $false
    }
  } catch {}
})

$bar.Add_Load({ Update-Layout; Update-Apps; $timer.Start() })
[Windows.Forms.Application]::Run($bar)
