$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$fqbn = 'arduino:avr:nano:cpu=atmega328old'
$port = 'COM6'

$sketches = @{
  'LED_Sequence'        = 'LED_Sequence';
  'Red_LED_Only'        = 'Red_LED_Only';
  'Flash_All_LEDs'      = 'Flash_All_LEDs';
  'Binary_4LED_Display' = 'Binary_4LED_Display';
}

function Ensure-ArduinoCLI {
  $cli = Get-ChildItem "$PSScriptRoot" -Filter arduino-cli.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($cli) { $env:PATH = "$($cli.DirectoryName);$env:PATH"; return }
  if (-not (Get-Command arduino-cli -ErrorAction SilentlyContinue)) {
    [System.Windows.Forms.MessageBox]::Show('arduino-cli not found. It will be downloaded locally.','Arduino Uploader', 'OK','Information') | Out-Null
    $url = 'https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Windows_64bit.zip'
    $zip = Join-Path $PSScriptRoot 'arduino-cli.zip'
    Invoke-WebRequest $url -OutFile $zip
    Expand-Archive $zip -DestinationPath $PSScriptRoot -Force
    Remove-Item $zip
    $cli = Get-ChildItem "$PSScriptRoot" -Filter arduino-cli.exe -Recurse | Select-Object -First 1
    if ($cli) { $env:PATH = "$($cli.DirectoryName);$env:PATH" } else { throw 'Failed to install arduino-cli.' }
  }
}

function Ensure-Cores {
  arduino-cli core update-index | Out-Null
  if (-not (arduino-cli core list | Select-String 'arduino:avr')) {
    arduino-cli core install arduino:avr | Out-Null
  }
}

function Reset-SerialPort([string]$p) {
  try {
    $sp = [System.IO.Ports.SerialPort]::new($p,9600,'None',8,'One')
    $sp.ReadTimeout = 150
    $sp.DtrEnable = $false
    $sp.RtsEnable = $false
    $sp.Open(); Start-Sleep -Milliseconds 120
    $sp.DtrEnable = $true;  $sp.RtsEnable = $true;  Start-Sleep -Milliseconds 120
    $sp.DtrEnable = $false; $sp.RtsEnable = $false
    $sp.Close()
  } catch {}
  try { cmd /c "mode ${p}:" | Out-Null } catch {}
}

function Upload-With-Retry([string]$folder, [int]$maxTries = 3) {
  for ($t=1; $t -le $maxTries; $t++) {
    Reset-SerialPort -p $port
    $compile = arduino-cli compile --fqbn $fqbn "$folder" 2>&1
    if ($LASTEXITCODE -ne 0) { return @{ ok=$false; log=($compile|Out-String) } }
    $upload  = arduino-cli upload -p $port --fqbn $fqbn "$folder" 2>&1
    if ($LASTEXITCODE -eq 0) { return @{ ok=$true; log=($upload|Out-String) } }
    $text = $upload | Out-String
    if ($text -like "*can't set com-state*") { Start-Sleep -Seconds 2; continue }
    return @{ ok=$false; log=$text }
  }
  return @{ ok=$false; log='Failed after retries' }
}

# GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Arduino Nano Uploader'
$form.Size = New-Object System.Drawing.Size(520, 360)
$form.StartPosition = 'CenterScreen'

$labelSketch = New-Object System.Windows.Forms.Label
$labelSketch.Text = 'Sketch:'
$labelSketch.Location = New-Object System.Drawing.Point(20,20)
$labelSketch.AutoSize = $true
$form.Controls.Add($labelSketch)

$combo = New-Object System.Windows.Forms.ComboBox
$combo.Location = New-Object System.Drawing.Point(80, 16)
$combo.Size = New-Object System.Drawing.Size(180, 24)
$combo.DropDownStyle = 'DropDownList'
$combo.Items.AddRange([string[]]$sketches.Keys)
$combo.SelectedIndex = 0
$form.Controls.Add($combo)

$btnUpload = New-Object System.Windows.Forms.Button
$btnUpload.Text = 'Upload'
$btnUpload.Location = New-Object System.Drawing.Point(280, 14)
$btnUpload.Size = New-Object System.Drawing.Size(90, 28)
$form.Controls.Add($btnUpload)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = 'Exit'
$btnExit.Location = New-Object System.Drawing.Point(380, 14)
$btnExit.Size = New-Object System.Drawing.Size(90, 28)
$form.Controls.Add($btnExit)

$txt = New-Object System.Windows.Forms.TextBox
$txt.Location = New-Object System.Drawing.Point(20, 60)
$txt.Size = New-Object System.Drawing.Size(450, 200)
$txt.Multiline = $true
$txt.ScrollBars = 'Vertical'
$txt.ReadOnly = $true
$form.Controls.Add($txt)

$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(20, 270)
$panel.Size = New-Object System.Drawing.Size(450, 50)
$form.Controls.Add($panel)

$labelInput = New-Object System.Windows.Forms.Label
$labelInput.Text = 'Binary Input (0-15/bits):'
$labelInput.Location = New-Object System.Drawing.Point(0, 6)
$labelInput.AutoSize = $true
$panel.Controls.Add($labelInput)

$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(180, 2)
$inputBox.Size = New-Object System.Drawing.Size(100, 24)
$panel.Controls.Add($inputBox)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = 'Send'
$btnSend.Location = New-Object System.Drawing.Point(290, 0)
$btnSend.Size = New-Object System.Drawing.Size(70, 28)
$panel.Controls.Add($btnSend)

Ensure-ArduinoCLI
Ensure-Cores

$serial = $null

function Append-Log([string]$line) { $txt.AppendText($line + [Environment]::NewLine) }

function Wait-ForPort([string]$p, [int]$ms = 8000) {
  $deadline = [DateTime]::UtcNow.AddMilliseconds($ms)
  while ([DateTime]::UtcNow -lt $deadline) {
    if ([System.IO.Ports.SerialPort]::GetPortNames() -contains $p) { return $true }
    Start-Sleep -Milliseconds 200
  }
  return $false
}

function Open-Serial {
  param([int]$baud=9600, [int]$tries=12)
  if (-not (Wait-ForPort -p $port -ms 6000)) { Append-Log "Port $port not present."; return $false }
  for ($i=1; $i -le $tries; $i++) {
    try {
      if ($serial) { try { if ($serial.IsOpen) { $serial.Close() } } catch {} $serial.Dispose() }
      $serial = [System.IO.Ports.SerialPort]::new($port,$baud,'None',8,'One')
      $serial.ReadTimeout = 200
      $serial.DtrEnable = $true
      $serial.RtsEnable = $true
      $serial.Open()
      Start-Sleep -Milliseconds 300
      Append-Log "Serial opened on $port (try $i)."
      return $true
    } catch {
      if ($i -eq 1) { Append-Log "Serial open failed (will retry): $_" }
      Reset-SerialPort -p $port
      Start-Sleep -Milliseconds 500
    }
  }
  Append-Log "Could not open serial on $port after $tries tries."
  return $false
}

$btnUpload.Add_Click({
  $name = $combo.SelectedItem
  $folder = Join-Path $PSScriptRoot $sketches[$name]
  Append-Log "Uploading $name to $port as $fqbn..."
  $res = Upload-With-Retry -folder $folder -maxTries 3
  Append-Log $res.log
  if (-not $res.ok) { Append-Log 'Upload failed.'; return }

  if ($name -eq 'Binary_4LED_Display') {
    # Give Windows a moment to re-enumerate the CH340 after upload
    Start-Sleep -Milliseconds 1000
    Reset-SerialPort -p $port
    Start-Sleep -Milliseconds 600
    [void](Open-Serial -baud 9600 -tries 12)
    Append-Log 'Interactive: enter 0-15 or bits, or type off/exit and click Send.'
  } else {
    if ($serial -and $serial.IsOpen) { $serial.Close() }
  }
})

$btnSend.Add_Click({
  if (-not ($serial -and $serial.IsOpen)) {
    Append-Log 'Serial not open. Attempting to open...'
    if (-not (Open-Serial -baud 9600 -tries 6)) { return }
  }
  $msg = $inputBox.Text
  if (-not $msg) { return }
  try {
    $serial.WriteLine($msg)
    Append-Log "> $msg"
  } catch { Append-Log "Write failed: $_" }
})

$btnExit.Add_Click({
  try { if ($serial -and $serial.IsOpen) { $serial.WriteLine('exit'); Start-Sleep -Milliseconds 50; $serial.Close() } } catch {}
  $form.Close()
})

[void]$form.ShowDialog()


