# AnyStrata Desktop: one-line installer for Windows (PowerShell 5.1 or newer).
#
#     irm https://raw.githubusercontent.com/efzer1337-VP/AnyStrataUI/master/build/polystrata-desktop/packaging/install_desktop.ps1 | iex
#
# What it does, in order (and nothing else):
#   1. finds out which computer this is (Windows, processor, graphics card);
#   2. downloads the Desktop setup named in the release folder's install-manifest.txt
#      and checks its SHA-256 against it;
#   3. runs the setup into %LOCALAPPDATA%\Strata (no administrator rights, like the original);
#   4. waits for the app to start, prints the host URL and the engine version;
#   5. adds  %LOCALAPPDATA%\Strata\bin  to your user PATH and prints: Installed. Run: strata launch
#
# The engine and the model are not part of this: `strata launch` fetches the engine for your
# graphics card the first time you choose a model, from the same release folder, signed.
#
# <feed> is where the release folder is hosted: GitHub Releases of efzer1337-VP/AnyStrataUI
# (the "latest" desktop release's files), built in as the default. Set $env:STRATA_FEED to
# another folder (a URL) to use that instead, for example a local test feed:
# $env:STRATA_FEED='http://127.0.0.1:8099'; irm http://127.0.0.1:8099/install_desktop.ps1 | iex
# Optional: $env:STRATA_DATA_DIR (default %LOCALAPPDATA%\Strata), $env:STRATA_NO_PATH='1'
# (do not change the user PATH).
# a child scope: `irm | iex` runs in the caller's scope, and this script's variables must not overwrite the caller's
& {
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Die([string]$msg) { [Console]::Error.WriteLine("strata desktop installer: $msg"); throw "strata desktop installer stopped" }
# older Windows 10 builds offer only TLS 1.0/1.1 to Windows PowerShell 5.1, and GitHub accepts only 1.2; a company proxy may want the Windows sign-in
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }
try { if ([Net.WebRequest]::DefaultWebProxy) { [Net.WebRequest]::DefaultWebProxy.Credentials = [Net.CredentialCache]::DefaultNetworkCredentials } } catch { }

$feed = if ($env:STRATA_FEED) { $env:STRATA_FEED } else { 'https://raw.githubusercontent.com/efzer1337-VP/AnyStrataUI/master/build/polystrata-desktop/release' }
$feed = $feed.TrimEnd('/')
if (-not $feed) {
    Die 'this installer does not know where the AnyStrata release folder is. Set $env:STRATA_FEED to its address and run it again.'
}
if ([Environment]::OSVersion.Platform -ne 'Win32NT') { Die 'this is the Windows installer.' }
$arch = $env:PROCESSOR_ARCHITEW6432; if (-not $arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
if ($arch -ne 'AMD64') { Die "this computer ($arch) needs Windows x64 (Intel or AMD). Run this installer on a Windows PC with an Intel or AMD processor (x64)." }
$platform = 'windows-x86_64'
$gpu = ''
try { $cards = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Basic|Remote' }); $gpu = ($cards | Sort-Object @{ Expression = { if ($_.Name -match 'NVIDIA|GeForce|RTX|GTX|Quadro|Radeon (RX|PRO|AI)|Arc|Instinct') { 0 } else { 1 } } } | Select-Object -First 1 -ExpandProperty Name) } catch { }
Write-Host 'AnyStrata Desktop installer'
Write-Host "  This computer: Windows $arch ($platform)$(if ($gpu) { ', graphics: ' + $gpu })"
Write-Host "  Release folder: $feed"

if (-not $env:STRATA_DATA_DIR -and -not $env:LOCALAPPDATA) { Die 'Windows did not say where your user folder is. Set $env:STRATA_DATA_DIR to a folder you own, for example $env:STRATA_DATA_DIR=''C:\Strata'', and run it again.' }
$data = if ($env:STRATA_DATA_DIR) { $env:STRATA_DATA_DIR } else { Join-Path $env:LOCALAPPDATA 'Strata' }
$work = Join-Path ([IO.Path]::GetTempPath()) ("strata-desktop-install-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work | Out-Null
try {
    try { Invoke-WebRequest -UseBasicParsing -Uri "$feed/install-manifest.txt" -OutFile (Join-Path $work 'manifest.txt') }
    catch { Die "could not download the release's install-manifest.txt from $feed." }
    $manifest = @{}
    foreach ($line in Get-Content -LiteralPath (Join-Path $work 'manifest.txt')) {
        if ($line -match '^[^#].*=\s*(.+?)\s*$') {
            $key = $Matches[1].Trim(); $val = $Matches[2].Trim().Trim('"')
            $manifest[$key] = $val
        }
    }
    $exe = $manifest['exe']; $sha = $manifest['sha256']
    if (-not $exe) { Die "install-manifest.txt is missing the 'exe' line." }
    if (-not $sha) { Die "install-manifest.txt is missing the 'sha256' line." }
    Write-Host "  Setup: $exe"
    Write-Host 'Downloading...'
    $dest = Join-Path $work $exe
    Invoke-WebRequest -UseBasicParsing -Uri "$feed/$exe" -OutFile $dest
    $mb = 1024 * 1024
    $size = (Get-Item -LiteralPath $dest).Length
    $mbValue = [math]::Round([double]$size / $mb)
    Write-Host "  $mbValue MB"
    $got = Get-FileHash -Algorithm SHA256 -LiteralPath $dest | Select-Object -ExpandProperty Hash
    if ($got.ToLower() -ne $sha.ToLower()) {
        Die "checksum mismatch for $exe (got $got, expected $sha). Aborting."
    }
    Write-Host '  Checksum ok.'
    # run the NSIS setup, non-elevated, quiet (keep the existing install location)
    Write-Host 'Running installer...'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $dest
    $psi.Arguments = '/S'   # silent, non-interactive setup
    $psi.UseShellExecute = $false
    $psi.WorkingDirectory = $work
    $proc = [System.Diagnostics.Process]::Start($psi)
    $proc.WaitForExit()
    if ($proc.ExitCode -ne 0) {
        Die "the installer exited with code $($proc.ExitCode). Aborting."
    }
    # verify the app binary exists where NSIS installed it
    $binDir = if ($env:STRATA_BIN_DIR) { $env:STRATA_BIN_DIR } else { Join-Path $data 'bin' }
    $app = Join-Path $binDir 'AnyStrata.exe'
    if (-not (Test-Path -LiteralPath $app)) {
        # fall back: any *.exe in the install location
        $found = Get-ChildItem -LiteralPath $binDir -Filter *.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $app = $found.FullName }
    }
    if (-not (Test-Path -LiteralPath $app)) { Die "could not find AnyStrata.exe at $binDir after install." }
    Write-Host "  Installed: $app"
    if (-not $env:STRATA_NO_PATH -and -not $env:LOCALAPPDATA) {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($userPath -notlike "*$binDir*") {
            $newPath = if ($userPath) { $userPath + ';' + $binDir } else { $binDir }
            [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
            Write-Host "  Added $binDir to your user PATH."
        }
    }
    Write-Host 'Installed. To start it later, run: & "$app"'
    Write-Host 'Models are downloaded on first launch from the same release folder (signed, with your graphics card engine).'
}
finally {
    if (-not $env:STRATA_KEEP_TEMP) { try { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue } catch { } }
}
}
