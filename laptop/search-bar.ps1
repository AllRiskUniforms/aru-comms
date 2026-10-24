# A Windows 98 style search box on Plato's RetroBar taskbar, in place of the Windows
# search bar that RetroBar hides. Clicking it opens the real Windows search (as Win+S
# does), so typing searches exactly like the normal taskbar search: programs, files,
# settings, the web, best match and recents. Drag the grip on its left to move it.
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
  [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);

  // Win+S: opens Windows search with its text box ready for typing.
  public static void OpenWindowsSearch() {
    keybd_event(0x5B, 0, 0, UIntPtr.Zero);  // left Windows key down
    keybd_event(0x53, 0, 0, UIntPtr.Zero);  // S down
    keybd_event(0x53, 0, 2, UIntPtr.Zero);  // S up
    keybd_event(0x5B, 0, 2, UIntPtr.Zero);  // Windows key up
  }

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

$bar = New-Object Windows.Forms.Form
$bar.FormBorderStyle = 'None'
$bar.ShowInTaskbar = $false
$bar.TopMost = $true
$bar.StartPosition = 'Manual'
$bar.BackColor = $Face
$bar.Font = New-Object Drawing.Font('Tahoma', 8.25)
$scale = if ($bar.DeviceDpi) { $bar.DeviceDpi / 96.0 } else { 1.0 }
function Px($n) { [int][Math]::Round($n * $scale) }

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

# Looks like a sunken 98 text box; clicking it hands off to Windows search.
$box = New-Object Windows.Forms.TextBox
$box.BorderStyle = 'Fixed3D'
$box.ReadOnly = $true
$box.TabStop = $false
$box.BackColor = [Drawing.Color]::White
$box.ForeColor = [Drawing.Color]::Gray
$box.Cursor = 'IBeam'
$box.Text = 'Type here to search'

$bar.Controls.AddRange(@($grip, $label, $box))

function Update-Layout {
  $screen = [Windows.Forms.Screen]::PrimaryScreen
  $top = $screen.WorkingArea.Bottom
  $height = $screen.Bounds.Bottom - $top
  if ($height -lt (Px 20)) { $height = Px 28; $top = $screen.Bounds.Bottom - $height }  # taskbar hidden or not at the bottom
  $barHeight = $height - (Px 6)
  $width = Px 230

  $grip.SetBounds((Px 2), 0, (Px 3) + 1, $barHeight)
  $label.Left = $grip.Right + (Px 4)
  $label.Top = [Math]::Max(0, [int](($barHeight - $label.PreferredHeight) / 2))
  $box.Left = $label.Left + $label.PreferredWidth + (Px 2)
  $box.Width = $width - $box.Left - (Px 2)
  $box.Top = [Math]::Max(0, [int](($barHeight - $box.Height) / 2))

  $x = $screen.Bounds.Right - $width - (Px 230)  # default: left of the tray and clock
  if (Test-Path $Settings) { try { $x = [int](Get-Content $Settings -Raw | ConvertFrom-Json).x } catch {} }
  $x = [Math]::Max(0, [Math]::Min($x, $screen.Bounds.Right - $width))
  $bar.SetBounds($x, $top + (Px 3), $width, $barHeight)
  $script:LayoutFor = $screen.WorkingArea
}

$openSearch = {
  $box.SelectionLength = 0
  [Native]::OpenWindowsSearch()
}
$box.Add_MouseDown($openSearch)
$label.Add_MouseDown($openSearch)

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
      if (-not $script:Hidden) { [Native]::Hide($bar.Handle); $script:Hidden = $true }
    } else {
      [Native]::ShowOnTop($bar.Handle)
      $script:Hidden = $false
    }
  } catch {}
})

$bar.Add_Load({ Update-Layout; $timer.Start() })
[Windows.Forms.Application]::Run($bar)
