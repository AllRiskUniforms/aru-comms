# Send to Plato: sends files to Plato over its private ntfy.sh channel. On Plato,
# messages.ps1 saves each one to Downloads and pops up a box to open it. Runs from the
# "Plato" entry in the right-click Send to menu, or from the "Send to Plato" desktop icon
# (drop files on it); setup-sender.ps1 makes both. The files come in as arguments.
# Settings (Plato's channel, and this computer's name) are in
# %LOCALAPPDATA%\ARU98\send-to-plato.json, never in the repo.
#
# ntfy.sh takes attachments of up to 2 MB, 20 MB per sender at a time, and deletes them
# after 3 hours. So a file is gzipped when that makes it smaller, then sent in parts of
# under 2 MB; Plato joins them back up and checks the SHA-256.

Add-Type -AssemblyName System.Windows.Forms
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PartSize = 1900000
$MaxSend = 18000000  # under the 20 MB that ntfy.sh holds per sender

function Say($text, $icon) { [void][Windows.Forms.MessageBox]::Show($text, 'Send to Plato', [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]$icon) }

function Format-Size($n) {
  if ($n -ge 1MB) { '{0:0.0} MB' -f ($n / 1MB) } elseif ($n -ge 1KB) { '{0:0} KB' -f ($n / 1KB) } else { "$n bytes" }
}

function Send-Part($url, [byte[]]$bytes) {
  $wc = New-Object Net.WebClient
  $wc.Headers['Content-Type'] = 'application/octet-stream'
  try { [void]$wc.UploadData($url, 'PUT', $bytes) }
  catch {
    $why = $_.Exception.Message
    $web = $_.Exception.InnerException
    if ($web -is [Net.WebException] -and $web.Response) {
      try { $body = (New-Object IO.StreamReader($web.Response.GetResponseStream())).ReadToEnd() | ConvertFrom-Json; if ($body.error) { $why = $body.error } } catch {}
    }
    throw "ntfy.sh refused it ($why)."
  }
  finally { $wc.Dispose() }
}

$settings = $null
try { $settings = Get-Content (Join-Path $env:LOCALAPPDATA 'ARU98\send-to-plato.json') -Raw | ConvertFrom-Json } catch {}
if (-not $settings.topic) { Say "Send to Plato isn't set up on this computer. See ""Send files to Plato"" in laptop\README.md." 'Warning'; return }
$files = @($args | Where-Object { $_ })
if (-not $files.Count) { Say 'Drop files on this icon, or right-click them and pick Send to > Plato.' 'Information'; return }

$sent = @()
$failed = @()
foreach ($path in $files) {
  $name = [IO.Path]::GetFileName($path)
  try {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'Only files can be sent. Zip a folder first (right-click > Send to > Compressed (zipped) folder).' }
    $info = Get-Item -LiteralPath $path
    if ($info.Length -eq 0) { throw 'It''s empty.' }
    if ($info.Length -gt 60MB) { throw "It's $(Format-Size $info.Length). Plato can take about 18 MB at a time; use a USB stick." }
    $bytes = [IO.File]::ReadAllBytes($info.FullName)
    $hash = -join ([Security.Cryptography.SHA256]::Create().ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })

    $mem = New-Object IO.MemoryStream
    $gz = New-Object IO.Compression.GZipStream($mem, [IO.Compression.CompressionMode]::Compress)
    $gz.Write($bytes, 0, $bytes.Length)
    $gz.Dispose()
    $packed = $mem.ToArray()
    $useGz = $packed.Length -lt $bytes.Length * 0.95
    $payload = $bytes
    if ($useGz) { $payload = $packed }
    if ($payload.Length -gt $MaxSend) { throw "It's $(Format-Size $payload.Length) even zipped. Plato can take about 18 MB at a time; use a USB stick." }

    $id = [guid]::NewGuid().ToString('N').Substring(0, 12)
    $parts = [int][Math]::Ceiling($payload.Length / $PartSize)
    for ($i = 0; $i -lt $parts; $i++) {
      Write-Host "Sending $name to Plato$(if ($parts -gt 1) { " (part $($i + 1) of $parts)" })..."
      $offset = $i * $PartSize
      $chunk = [byte[]]::new([Math]::Min($PartSize, $payload.Length - $offset))
      [Array]::Copy($payload, $offset, $chunk, 0, $chunk.Length)
      $meta = [ordered]@{ id = $id; part = $i + 1; parts = $parts; name = $name; size = $bytes.Length; gz = $useGz; sha256 = $hash; from = $settings.from } | ConvertTo-Json -Compress
      $query = 'filename=' + [uri]::EscapeDataString("$id-$($i + 1).part") +
        '&title=' + [uri]::EscapeDataString("File from $($settings.from)") +
        '&message=' + [uri]::EscapeDataString("aru98-file $meta")
      Send-Part "https://ntfy.sh/$($settings.topic)?$query" $chunk
    }
    $sent += "$name ($(Format-Size $bytes.Length))"
  } catch {
    $failed += "${name}: $($_.Exception.Message)"
  }
}

$report = @()
if ($sent.Count) { $report += 'Sent to Plato. It pops up there within about 10 seconds and lands in Downloads:'; $report += $sent }
if ($failed.Count) { if ($report.Count) { $report += '' }; $report += 'Not sent:'; $report += $failed }
Say ($report -join "`r`n") $(if ($failed.Count) { 'Warning' } else { 'Information' })
