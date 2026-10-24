# Messages to Plato. Anything published to Plato's private ntfy.sh topic (named in the
# gitignored messages-config.js) pops up as its own Windows 98 style message box at a
# random spot, on top of everything, the ARU 98 lock screen included. Each box stays,
# through locks, unlocks and restarts, until someone clicks OK or x. Boxes and their
# places are saved in %LOCALAPPDATA%\ARU98\messages.json.
# start-kiosk.cmd starts this hidden at sign-in; starting it again replaces the running copy.

$Config = Join-Path $PSScriptRoot 'messages-config.js'
$Topic = if (Test-Path $Config) { [regex]::Match((Get-Content $Config -Raw), "topic: '([^']+)'").Groups[1].Value }
if (-not $Topic) { return }

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class Popup {
  [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);

  // Above every other window, the lock screen included, without taking focus
  // (HWND_TOPMOST with NOSIZE|NOMOVE|NOACTIVATE).
  public static void KeepOnTop(IntPtr hwnd) { SetWindowPos(hwnd, new IntPtr(-1), 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0010); }
}
'@

# One copy at a time, always the newest code.
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
  Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*messages.ps1*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Windows.Forms.Application]::VisualStyleState = 'NoneEnabled'  # classic 3D buttons, like 98
$StateFile = Join-Path $env:LOCALAPPDATA 'ARU98\messages.json'
New-Item -ItemType Directory -Force (Split-Path $StateFile) | Out-Null
$Face = [Drawing.Color]::FromArgb(192, 192, 192)
$Font = New-Object Drawing.Font('Tahoma', 8.25)
$BoldFont = New-Object Drawing.Font('Tahoma', 8.25, [Drawing.FontStyle]::Bold)
$scale = 1.0
try { $g = [Drawing.Graphics]::FromHwnd([IntPtr]::Zero); $scale = $g.DpiX / 96.0; $g.Dispose() } catch {}
function Px($n) { [int][Math]::Round($n * $scale) }

# ── Saved state ──────────────────────────────────────────────────────────────
$Pending = [ordered]@{}   # message id -> @{ id; title; text; time; x; y }
$Boxes = @{}              # message id -> its window
$LastId = $null
$LastCell = -1
try {
  $saved = Get-Content $StateFile -Raw | ConvertFrom-Json
  $LastId = $saved.lastId
  foreach ($m in @($saved.pending)) { if ($m.id) { $Pending[$m.id] = $m } }
} catch {}

function Save-State {
  try {
    [pscustomobject]@{ lastId = $script:LastId; pending = @($script:Pending.Values) } |
      ConvertTo-Json -Depth 4 | Set-Content $StateFile -Encoding UTF8
  } catch {}
}

# ── Where boxes go ───────────────────────────────────────────────────────────
# The screen is split 3x3. Each box goes somewhere random in an outer cell, never the
# same cell as the box before it, and in an empty cell when there is one. It also never
# covers $clear, the lock screen's password box in the middle (420x142, plus a margin).
function Get-Cell($area, $x, $y, $w, $h) {
  $col = [Math]::Min(2, [Math]::Max(0, [Math]::Floor(($x + $w / 2 - $area.Left) / ($area.Width / 3))))
  $row = [Math]::Min(2, [Math]::Max(0, [Math]::Floor(($y + $h / 2 - $area.Top) / ($area.Height / 3))))
  [int]($row * 3 + $col)
}

function Select-Spot($area, $w, $h, $taken, $last, $clear) {
  $cells = @(0..8 | Where-Object { $_ -ne 4 -and $_ -ne $last })
  $free = @($cells | Where-Object { $_ -notin $taken })
  $cw = $area.Width / 3
  $ch = $area.Height / 3
  for ($try = 0; $try -lt 50; $try++) {
    $cell = if ($free.Count) { $free | Get-Random } else { $cells | Get-Random }
    $x = $area.Left + ($cell % 3) * $cw + (Get-Random -Minimum 0.0 -Maximum ([Math]::Max(1.0, $cw - $w / 2)))
    $y = $area.Top + [Math]::Floor($cell / 3) * $ch + (Get-Random -Minimum 0.0 -Maximum ([Math]::Max(1.0, $ch - $h / 2)))
    $x = [Math]::Max($area.Left, [Math]::Min($x, $area.Left + $area.Width - $w))
    $y = [Math]::Max($area.Top, [Math]::Min($y, $area.Top + $area.Height - $h))
    $overlaps = $clear -and $x -lt $clear.Right -and $x + $w -gt $clear.Left -and $y -lt $clear.Bottom -and $y + $h -gt $clear.Top
    if (-not $overlaps) { break }
  }
  @{ X = [int]$x; Y = [int]$y; Cell = $cell }
}

# ntfy's poll output: one JSON object per line. Keep real messages only.
function Read-Messages($text) {
  foreach ($line in ($text -split "`n")) {
    if (-not $line.Trim()) { continue }
    try { $m = $line | ConvertFrom-Json } catch { continue }
    if ($m.event -eq 'message' -and $m.message) { $m }
  }
}

# ── The boxes ────────────────────────────────────────────────────────────────
function Get-LockWindow {
  Get-Process msedge -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -like 'ARU 98*' -and $_.MainWindowTitle -notlike 'ARU 98 unlocked*' } |
    Select-Object -First 1
}

function Close-MessageBox($id) {
  if ($script:Boxes.Contains($id)) { $script:Boxes[$id].Close(); $script:Boxes.Remove($id) }
  $script:Pending.Remove($id)
  Save-State
  $lock = Get-LockWindow  # hand the keyboard back to the password box
  if ($lock) { [void][Popup]::SetForegroundWindow($lock.MainWindowHandle) }
}

function Show-MessageBox($m) {
  $width = Px 340
  $inset = Px 3
  $form = New-Object Windows.Forms.Form
  $form.FormBorderStyle = 'None'
  $form.ShowInTaskbar = $false
  $form.TopMost = $true
  $form.StartPosition = 'Manual'
  $form.BackColor = $Face
  $form.Font = $Font
  $form.Tag = $m.id
  # Raised Windows 98 frame.
  $form.Add_Paint({
    param($s, $e)
    $w = $s.Width - 1; $h = $s.Height - 1; $gr = $e.Graphics
    $gr.DrawLine([Drawing.Pens]::LightGray, 0, 0, $w, 0); $gr.DrawLine([Drawing.Pens]::LightGray, 0, 0, 0, $h)
    $gr.DrawLine([Drawing.Pens]::Black, $w, 0, $w, $h); $gr.DrawLine([Drawing.Pens]::Black, 0, $h, $w, $h)
    $gr.DrawLine([Drawing.Pens]::White, 1, 1, $w - 1, 1); $gr.DrawLine([Drawing.Pens]::White, 1, 1, 1, $h - 1)
    $gr.DrawLine([Drawing.Pens]::Gray, $w - 1, 1, $w - 1, $h - 1); $gr.DrawLine([Drawing.Pens]::Gray, 1, $h - 1, $w - 1, $h - 1)
  })

  # Title bar: navy to blue, bold white title, and the close button.
  $bar = New-Object Windows.Forms.Panel
  $bar.SetBounds($inset, $inset, $width - 2 * $inset, (Px 18))
  $bar.Tag = [string]$m.title
  $bar.Add_Paint({
    param($s, $e)
    $rect = New-Object Drawing.Rectangle(0, 0, $s.Width, $s.Height)
    $brush = New-Object Drawing.Drawing2D.LinearGradientBrush($rect, [Drawing.Color]::FromArgb(0, 0, 128), [Drawing.Color]::FromArgb(16, 132, 208), 0.0)
    $e.Graphics.FillRectangle($brush, $rect)
    $brush.Dispose()
    [Windows.Forms.TextRenderer]::DrawText($e.Graphics, $s.Tag, $BoldFont, (New-Object Drawing.Point((Px 3), (Px 2))), [Drawing.Color]::White)
  })
  $x = New-Object Windows.Forms.Button
  $x.Font = New-Object Drawing.Font('Marlett', 7)
  $x.Text = 'r'  # Marlett's close glyph, as on real 98 title bars
  $x.SetBounds($bar.Width - (Px 18), (Px 2), (Px 16), (Px 14))
  $x.TabStop = $false
  $x.Tag = $m.id
  $x.Add_Click({ param($s) Close-MessageBox $s.Tag })
  $bar.Controls.Add($x)

  # Drag the title bar to move the box; the new spot is saved.
  $bar.Add_MouseDown({ param($s, $e) if ($e.Button -eq 'Left') { $script:Drag = @{ Form = $s.Parent; Dx = [Windows.Forms.Cursor]::Position.X - $s.Parent.Left; Dy = [Windows.Forms.Cursor]::Position.Y - $s.Parent.Top } } })
  $bar.Add_MouseMove({ if ($script:Drag) { $p = [Windows.Forms.Cursor]::Position; $script:Drag.Form.Location = New-Object Drawing.Point(($p.X - $script:Drag.Dx), ($p.Y - $script:Drag.Dy)) } })
  $bar.Add_MouseUp({
    if ($script:Drag) {
      $f = $script:Drag.Form; $rec = $script:Pending[$f.Tag]
      if ($rec) { $rec.x = $f.Left; $rec.y = $f.Top; Save-State }
      $script:Drag = $null
    }
  })

  # Body: info icon, the message, when it was sent.
  $icon = New-Object Windows.Forms.Panel
  $icon.SetBounds((Px 14), $bar.Bottom + (Px 12), (Px 32), (Px 32))
  $icon.Add_Paint({
    param($s, $e)
    $gr = $e.Graphics; $gr.SmoothingMode = 'AntiAlias'
    $r = New-Object Drawing.Rectangle(0, 0, ($s.Width - 1), ($s.Height - 1))
    $gr.FillEllipse((New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(0, 0, 200))), $r)
    $gr.DrawEllipse([Drawing.Pens]::Black, $r)
    $f = New-Object Drawing.Font('Times New Roman', ($s.Height * 0.5), [Drawing.FontStyle]'Bold, Italic', [Drawing.GraphicsUnit]::Pixel)
    [Windows.Forms.TextRenderer]::DrawText($gr, 'i', $f, $r, [Drawing.Color]::White, [Windows.Forms.TextFormatFlags]'HorizontalCenter, VerticalCenter')
  })

  $textLeft = $icon.Right + (Px 12)
  $textWidth = $width - $textLeft - (Px 14)
  $flags = [Windows.Forms.TextFormatFlags]'WordBreak, TextBoxControl'
  $needed = [Windows.Forms.TextRenderer]::MeasureText([string]$m.text, $Font, (New-Object Drawing.Size($textWidth, 0)), $flags).Height
  $text = New-Object Windows.Forms.TextBox
  $text.Multiline = $true
  $text.ReadOnly = $true
  $text.BorderStyle = 'None'
  $text.BackColor = $Face
  $text.TabStop = $false
  $text.Text = ([string]$m.text) -replace "`r?`n", "`r`n"
  $text.SetBounds($textLeft, $icon.Top + (Px 4), $textWidth, [Math]::Min($needed + (Px 4), (Px 240)))
  if ($needed + (Px 4) -gt (Px 240)) { $text.ScrollBars = 'Vertical' }

  $sent = New-Object Windows.Forms.Label
  $sent.AutoSize = $true
  $sent.ForeColor = [Drawing.Color]::FromArgb(64, 64, 64)
  $sent.Text = 'Sent ' + [DateTimeOffset]::FromUnixTimeSeconds([int64]$m.time).ToLocalTime().ToString('ddd h:mm tt')
  $sent.Location = New-Object Drawing.Point($textLeft, ($text.Bottom + (Px 6)))

  $ok = New-Object Windows.Forms.Button
  $ok.Text = 'OK'
  $ok.Tag = $m.id
  $okTop = [Math]::Max($icon.Bottom, $sent.Top + $sent.PreferredHeight) + (Px 12)
  $ok.SetBounds([int](($width - (Px 75)) / 2), $okTop, (Px 75), (Px 23))
  $ok.Add_Click({ param($s) Close-MessageBox $s.Tag })

  $form.Controls.AddRange(@($bar, $icon, $text, $sent, $ok))
  $form.Size = New-Object Drawing.Size($width, ($ok.Bottom + (Px 12)))

  # Its spot: the saved one, or a fresh random one.
  $area = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea
  $areaH = @{ Left = $area.Left; Top = $area.Top; Width = $area.Width; Height = $area.Height }
  if ($null -eq $m.x -or $null -eq $m.y) {
    $taken = @($script:Boxes.Values | ForEach-Object { Get-Cell $areaH $_.Left $_.Top $_.Width $_.Height })
    $screen = [Windows.Forms.Screen]::PrimaryScreen.Bounds
    $cx = $screen.Left + $screen.Width / 2; $cy = $screen.Top + $screen.Height / 2
    $clear = @{ Left = $cx - (Px 230); Right = $cx + (Px 230); Top = $cy - (Px 95); Bottom = $cy + (Px 95) }
    $spot = Select-Spot $areaH $form.Width $form.Height $taken $script:LastCell $clear
    $script:LastCell = $spot.Cell
    $m.x = $spot.X; $m.y = $spot.Y
  }
  $form.Location = New-Object Drawing.Point(
    [Math]::Max($area.Left, [Math]::Min([int]$m.x, $area.Right - $form.Width)),
    [Math]::Max($area.Top, [Math]::Min([int]$m.y, $area.Bottom - $form.Height)))

  $script:Boxes[$m.id] = $form
  $before = [Popup]::GetForegroundWindow()
  $form.Show()
  [Popup]::KeepOnTop($form.Handle)
  if ($before -ne [IntPtr]::Zero) { [void][Popup]::SetForegroundWindow($before) }  # don't take the keyboard
  [Media.SystemSounds]::Asterisk.Play()
}

# ── Fetching ─────────────────────────────────────────────────────────────────
# Every 10 s, ask ntfy.sh for anything newer than the last message seen (on the first
# run, the last 12 hours). The download runs in the background; the timer below picks
# up its result on this thread, so the boxes never freeze and no PowerShell code runs
# off the UI thread.
$client = New-Object Net.WebClient
$client.Encoding = [Text.Encoding]::UTF8
$script:Download = $null

function Start-Fetch {
  if ($script:Download) { return }
  $since = if ($script:LastId) { $script:LastId } else { '12h' }
  try { $script:Download = $client.DownloadStringTaskAsync([uri]"https://ntfy.sh/$Topic/json?poll=1&since=$since") } catch {}
}

function Receive-Fetch {
  $d = $script:Download
  if (-not $d -or -not $d.IsCompleted) { return }
  $script:Download = $null
  if ($d.IsFaulted -or $d.IsCanceled) { return }
  foreach ($m in @(Read-Messages $d.Result)) {
    $script:LastId = $m.id
    if ($script:Pending.Contains($m.id)) { continue }
    $text = [string]$m.message
    $rec = [pscustomobject]@{
      id = $m.id
      title = $(if ($m.title) { [string]$m.title } else { 'Message' })
      text = $text.Substring(0, [Math]::Min(2000, $text.Length))
      time = [int64]$m.time
      x = $null
      y = $null
    }
    $script:Pending[$m.id] = $rec
    Show-MessageBox $rec
  }
  Save-State
}

# One timer, every half second: pick up finished downloads, start a new one every 10 s
# (and straight away), and once a second keep the boxes above everything (the lock
# window raises itself when it opens).
$script:Ticks = 0
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 500
$timer.Add_Tick({
  try {
    Receive-Fetch
    if ($script:Ticks % 20 -eq 0) { Start-Fetch }
    if ($script:Ticks % 2 -eq 0) { foreach ($f in @($script:Boxes.Values)) { [Popup]::KeepOnTop($f.Handle) } }
  } catch {}
  $script:Ticks++
})

foreach ($m in @($Pending.Values)) { Show-MessageBox $m }
$timer.Start()
[Windows.Forms.Application]::Run((New-Object Windows.Forms.ApplicationContext))
