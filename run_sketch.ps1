$ErrorActionPreference = 'Stop'

# Configuration
$fqbn = 'arduino:avr:nano:cpu=atmega328old' # Nano, Old Bootloader
$port = 'COM6'

# Sketches list (name -> folder path)
$sketches = @{
  'LED_Sequence'     = 'LED_Sequence';
  'Red_LED_Only'     = 'Red_LED_Only';
  'Flash_All_LEDs'   = 'Flash_All_LEDs';
  'Binary_4LED_Display' = 'Binary_4LED_Display';
}

function Ensure-ArduinoCLI {
  $cli = Get-ChildItem "$PSScriptRoot" -Filter arduino-cli.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($cli) { $env:PATH = "$($cli.DirectoryName);$env:PATH"; return }
  if (-not (Get-Command arduino-cli -ErrorAction SilentlyContinue)) {
    Write-Host 'arduino-cli not found. Installing locally...' -ForegroundColor Yellow
    $url = 'https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Windows_64bit.zip'
    $zip = "$PSScriptRoot/arduino-cli.zip"
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
    $sp.Open()
    Start-Sleep -Milliseconds 120
    $sp.DtrEnable = $true
    $sp.RtsEnable = $true
    Start-Sleep -Milliseconds 120
    $sp.DtrEnable = $false
    $sp.RtsEnable = $false
    $sp.Close()
  } catch {
    # Ignore; port may be busy. We'll still attempt upload.
  }
  try { cmd /c "mode ${p}:" | Out-Null } catch {}
}

function Upload-With-Retry([string]$folder, [int]$maxTries = 3) {
  for ($t=1; $t -le $maxTries; $t++) {
    Write-Host "[Attempt $t/$maxTries] Resetting $port and uploading..." -ForegroundColor DarkCyan
    Reset-SerialPort -p $port
    $compile = arduino-cli compile --fqbn $fqbn "$folder" 2>&1
    $compile | Write-Host
    if ($LASTEXITCODE -ne 0) { return $false }
    $upload = arduino-cli upload -p $port --fqbn $fqbn "$folder" 2>&1
    $upload | Write-Host
    if ($LASTEXITCODE -eq 0) { return $true }
    $uploadText = $upload | Out-String
    if ($uploadText -like "*can't set com-state*") {
      Write-Host 'Windows serial stack error; retrying shortly...' -ForegroundColor Yellow
      Start-Sleep -Seconds 2
      continue
    }
    return $false
  }
  return $false
}

function Choose-Sketch {
  Write-Host 'Choose a sketch to upload (or 0 to Exit):' -ForegroundColor Cyan
  $i = 1
  $keys = @()
  foreach ($k in $sketches.Keys) { Write-Host ("  [$i] $k"); $keys += $k; $i++ }
  Write-Host '  [0] Exit'
  $choice = Read-Host 'Enter number'
  if ($choice -eq '0') { return $null }
  if (-not ($choice -as [int]) -or $choice -lt 1 -or $choice -gt $keys.Count) { Write-Host 'Invalid selection.' -ForegroundColor Red; return (Choose-Sketch) }
  return $keys[$choice-1]
}

Ensure-ArduinoCLI
Ensure-Cores

while ($true) {
  $name = Choose-Sketch
  if (-not $name) { Write-Host 'Exiting.' -ForegroundColor Yellow; break }
  $folder = Join-Path $PSScriptRoot $sketches[$name]

  Write-Host "Uploading $name to $port as $fqbn..." -ForegroundColor Green
  $ok = Upload-With-Retry -folder $folder -maxTries 3
  if (-not $ok) { Write-Host 'Upload failed after retries. Ensure no Serial Monitor/other app is open, then try again.' -ForegroundColor Red; continue }

  # If we uploaded the binary display sketch, offer interactive loop
  if ($name -eq 'Binary_4LED_Display') {
    Write-Host "Interactive mode: type a number 0-15, 'off', or 'exit'." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop interactive session and pick another sketch." -ForegroundColor DarkCyan
    try {
      $portHandle = [System.IO.Ports.SerialPort]::new($port,9600,'None',8,'One')
      $portHandle.ReadTimeout = 200
      $portHandle.Open()
      Start-Sleep -Milliseconds 300
      while ($true) {
        $input = Read-Host 'Enter value (0-15/binary/off/exit)'
        $portHandle.WriteLine($input)
        if ($input -eq 'exit') { break }
      }
      $portHandle.Close()
    } catch {
      Write-Host "Serial interaction failed: $_" -ForegroundColor Red
    }
  }
}

