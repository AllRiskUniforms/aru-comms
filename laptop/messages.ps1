# Messages to Plato. Anything published to Plato's private ntfy.sh topic (named in the
# gitignored messages-config.js) pops up as its own Windows 98 style message box at a
# random spot, on top of everything, the ARU 98 lock screen included. Each box stays,
# through locks, unlocks and restarts, until someone clicks OK or x. Boxes and their
# places are saved in %LOCALAPPDATA%\ARU98\messages.json.
# Files come the same way (from send-to-plato.ps1, or attached on the ntfy.sh page): each
# is saved to Downloads and gets a box with Open and Show in folder. Nothing opens by itself.
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
$Downloads = Join-Path $env:USERPROFILE 'Downloads'
try { $p = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path; if ($p) { $Downloads = $p } } catch {}
# Files of these types run as programs, so their boxes get no Open button.
$RunnableTypes = '.exe', '.msi', '.bat', '.cmd', '.com', '.scr', '.pif', '.ps1', '.vbs', '.vbe', '.js', '.jse', '.wsf', '.wsh', '.hta', '.lnk', '.reg', '.cpl', '.msc', '.jar'

# ── Saved state ──────────────────────────────────────────────────────────────
$Pending = [ordered]@{}   # message id -> @{ id; title; text; time; x; y; file }
$Incoming = [ordered]@{}  # file id -> @{ id; name; size; gz; sha256; from; note; parts; urls; time }
$Boxes = @{}              # message id -> its window
$LastId = $null
$LastCell = -1
try {
  $saved = Get-Content $StateFile -Raw | ConvertFrom-Json
  $LastId = $saved.lastId
  foreach ($m in @($saved.pending)) { if ($m.id) { $Pending[$m.id] = $m } }
  foreach ($t in @($saved.incoming)) { if ($t.id) { $Incoming[[string]$t.id] = $t } }
} catch {}

function Save-State {
  try {
    [pscustomobject]@{ lastId = $script:LastId; pending = @($script:Pending.Values); incoming = @($script:Incoming.Values) } |
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

# A received file's Open and Show in folder buttons. Both also close its box.
function Open-File($id, $inFolder) {
  $path = [string]$script:Pending[$id].file
  Close-MessageBox $id
  if (-not $path -or -not (Test-Path -LiteralPath $path)) { return }
  if ($inFolder) { Start-Process explorer.exe "/select,`"$path`"" } else { Invoke-Item -LiteralPath $path }
}

function New-BoxButton($label, $w, $id, $onClick) {
  $b = New-Object Windows.Forms.Button
  $b.Text = $label
  $b.Tag = $id
  $b.Size = New-Object Drawing.Size((Px $w), (Px 23))
  $b.Add_Click($onClick)
  $b
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

  # Buttons, centred: OK, and for a file, Open (not for programs) and Show in folder first.
  $buttons = @()
  if ($m.file) {
    if ([IO.Path]::GetExtension([string]$m.file) -notin $RunnableTypes) {
      $buttons += New-BoxButton 'Open' 75 $m.id { param($s) Open-File $s.Tag $false }
    }
    $buttons += New-BoxButton 'Show in folder' 95 $m.id { param($s) Open-File $s.Tag $true }
  }
  $buttons += New-BoxButton 'OK' 75 $m.id { param($s) Close-MessageBox $s.Tag }
  $top = [Math]::Max($icon.Bottom, $sent.Top + $sent.PreferredHeight) + (Px 12)
  $left = [int](($width - ($buttons | Measure-Object Width -Sum).Sum - (Px 6) * ($buttons.Count - 1)) / 2)
  foreach ($b in $buttons) { $b.Location = New-Object Drawing.Point($left, $top); $left += $b.Width + (Px 6) }

  $form.Controls.AddRange(@($bar, $icon, $text, $sent) + $buttons)
  $form.Size = New-Object Drawing.Size($width, ($top + (Px 23) + (Px 12)))

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

function Add-Box($id, $title, $text, $time, $file) {
  $rec = [pscustomobject]@{ id = $id; title = $title; text = $text; time = $time; x = $null; y = $null; file = $file }
  $script:Pending[$id] = $rec
  Show-MessageBox $rec
  Save-State
}

function Receive-Fetch {
  $d = $script:Download
  if (-not $d -or -not $d.IsCompleted) { return }
  $script:Download = $null
  if ($d.IsFaulted -or $d.IsCanceled) { return }
  foreach ($m in @(Read-Messages $d.Result)) {
    $script:LastId = $m.id
    if ($m.attachment -and (Add-FilePart $m)) { continue }
    if ($script:Pending.Contains($m.id)) { continue }
    $text = [string]$m.message
    $title = if ($m.title) { [string]$m.title } else { 'Message' }
    Add-Box $m.id $title ($text.Substring(0, [Math]::Min(2000, $text.Length))) ([int64]$m.time) $null
  }
  Save-State
}

# ── Files ────────────────────────────────────────────────────────────────────
# ntfy.sh takes attachments of up to 2 MB and deletes them after 3 hours. send-to-plato.ps1
# gzips a file when that helps and sends it in parts of under 2 MB, each with the message
# "aru98-file {id, part, parts, name, size, gz, sha256, from}". A file attached on the
# ntfy.sh page arrives as one plain attachment instead, maybe with a note. Once all of a
# file's parts are listed, they're downloaded one at a time (in the background, like the
# fetch), joined, unzipped, checked and saved to Downloads.
$fileClient = New-Object Net.WebClient
$script:FileJob = $null

# $true if $m was part of a file. Anything else with an attachment shows as a plain message.
function Add-FilePart($m) {
  $url = [string]$m.attachment.url
  if ($url -notlike 'https://ntfy.sh/file/*') { return $false }  # files uploaded to ntfy.sh only, never links elsewhere
  $text = [string]$m.message
  if ($text.StartsWith('aru98-file ')) {
    try { $meta = $text.Substring(11) | ConvertFrom-Json } catch { return $false }
  } else {
    $note = if ($text -notlike 'You received a file:*') { $text.Substring(0, [Math]::Min(1000, $text.Length)) } else { '' }
    $meta = [pscustomobject]@{ id = $m.id; part = 1; parts = 1; name = $m.attachment.name; size = $m.attachment.size; gz = $false; sha256 = ''; from = $m.title; note = $note }
  }
  $parts = [int]$meta.parts
  $part = [int]$meta.part
  if (-not $meta.id -or $parts -lt 1 -or $parts -gt 40 -or $part -lt 1 -or $part -gt $parts) { return $false }
  $t = $script:Incoming[[string]$meta.id]
  if (-not $t) {
    $t = [pscustomobject]@{
      id = [string]$meta.id; name = [string]$meta.name; size = [int64]$meta.size; gz = [bool]$meta.gz; sha256 = [string]$meta.sha256
      from = [string]$meta.from; note = [string]$meta.note; parts = $parts; urls = [object[]]::new($parts); time = 0
    }
    $script:Incoming[$t.id] = $t
  }
  if ($part -le @($t.urls).Count) { $t.urls[$part - 1] = $url }
  $t.time = [int64]$m.time
  $true
}

function Step-Files {
  $job = $script:FileJob
  if ($job) {
    if (-not $job.Task.IsCompleted) { return }
    if ($job.Task.IsFaulted -or $job.Task.IsCanceled) { $script:FileJob = $null; Stop-File $job.File; return }
    $bytes = $job.Task.Result
    $job.Data.Write($bytes, 0, $bytes.Length)
    $job.Index = $job.Index + 1
    if ($job.Index -lt $job.File.parts) {
      try { $job.Task = $fileClient.DownloadDataTaskAsync([uri]$job.File.urls[$job.Index]) } catch { $script:FileJob = $null; Stop-File $job.File }
      return
    }
    $script:FileJob = $null
    Save-File $job.File $job.Data.ToArray()
    return
  }
  $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  foreach ($t in @($script:Incoming.Values)) {
    $missing = 0
    foreach ($u in $t.urls) { if (-not $u) { $missing++ } }
    if ($missing -eq 0) {
      try { $script:FileJob = @{ File = $t; Index = 0; Data = (New-Object IO.MemoryStream); Task = $fileClient.DownloadDataTaskAsync([uri]$t.urls[0]) } }
      catch { Stop-File $t }
      return
    }
    # Some parts never came, and ntfy.sh has deleted the rest by now. The sender was told.
    if ($now - $t.time -gt 3 * 3600) { $script:Incoming.Remove($t.id); Save-State }
  }
}

function Get-FileTitle($t) { if ($t.from) { "File from $($t.from)" } else { 'File' } }

function Format-Size($n) {
  if ($n -ge 1MB) { '{0:0.0} MB' -f ($n / 1MB) } elseif ($n -ge 1KB) { '{0:0} KB' -f ($n / 1KB) } else { "$n bytes" }
}

function Stop-File($t) {
  $script:Incoming.Remove($t.id)
  Add-Box "file-$($t.id)" (Get-FileTitle $t) "$($t.name) didn't come through. Files wait on ntfy.sh for only 3 hours, so send it again." ([int64]$t.time) $null
}

# Downloads\<name>, or <name> (2) etc. if that's taken. The name is the sender's, so it's cleaned up first.
function Get-FreePath($name) {
  $name = ([string]$name -split '[\\/]')[-1]
  foreach ($c in [IO.Path]::GetInvalidFileNameChars()) { $name = $name.Replace([string]$c, '_') }
  $name = $name.Trim(' .')
  if (-not $name) { $name = 'file' }
  $ext = [IO.Path]::GetExtension($name)
  $base = $name.Substring(0, $name.Length - $ext.Length)
  if ($base.Length -gt 100) { $base = $base.Substring(0, 100) }
  $path = Join-Path $Downloads "$base$ext"
  for ($n = 2; Test-Path -LiteralPath $path; $n++) { $path = Join-Path $Downloads "$base ($n)$ext" }
  $path
}

function Save-File($t, [byte[]]$data) {
  try {
    if ($t.gz) {
      $gz = [IO.Compression.GZipStream]::new([IO.MemoryStream]::new($data), [IO.Compression.CompressionMode]::Decompress)
      $out = New-Object IO.MemoryStream
      $gz.CopyTo($out)
      $gz.Dispose()
      $data = $out.ToArray()
    }
    $hash = -join ([Security.Cryptography.SHA256]::Create().ComputeHash($data) | ForEach-Object { $_.ToString('x2') })
    if ($t.sha256 -and $hash -ne $t.sha256) { throw 'damaged on the way' }
    $path = Get-FreePath $t.name
    [IO.File]::WriteAllBytes($path, $data)
    # Marked as from the internet, as a browser download would be, so Windows warns before running it.
    try { Set-Content -LiteralPath $path -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3" } catch {}
  } catch { Stop-File $t; return }
  $script:Incoming.Remove($t.id)
  $text = "$([IO.Path]::GetFileName($path)) ($(Format-Size $data.Length))`r`nSaved in Downloads."
  if ($t.note) { $text = "$($t.note)`r`n`r`n$text" }
  Add-Box "file-$($t.id)" (Get-FileTitle $t) $text ([int64]$t.time) $path
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
    Step-Files
    if ($script:Ticks % 20 -eq 0) { Start-Fetch }
    if ($script:Ticks % 2 -eq 0) { foreach ($f in @($script:Boxes.Values)) { [Popup]::KeepOnTop($f.Handle) } }
  } catch {}
  $script:Ticks++
})

foreach ($m in @($Pending.Values)) { Show-MessageBox $m }
$timer.Start()
[Windows.Forms.Application]::Run((New-Object Windows.Forms.ApplicationContext))
