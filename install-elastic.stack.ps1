#requires -Version 5.1
<#
.SYNOPSIS
    Downloads, verifies, and extracts Elasticsearch, Kibana, and Logstash on Windows.

.DESCRIPTION
    Downloads matching Elastic Stack ZIP archives from artifacts.elastic.co,
    verifies each archive against Elastic's SHA-512 checksum, extracts the
    products into a common installation directory, and creates launcher scripts.

.PARAMETER Version
    Elastic Stack version to install. All products use the same version.

.PARAMETER InstallRoot
    Root directory for the installation. The default is C:\Elastic.

.PARAMETER Force
    Re-download archives and replace existing product directories.

.PARAMETER KeepArchives
    Keep ZIP and SHA-512 files after a successful installation.

.EXAMPLE
    .\install-elastic-stack.ps1

.EXAMPLE
    .\install-elastic-stack.ps1 -Version 9.4.3 -InstallRoot D:\Elastic -KeepArchives

.EXAMPLE
    .\install-elastic-stack.ps1 -Force
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version = '9.4.3',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$InstallRoot = 'C:\Elastic',

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$KeepArchives
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Assert-WindowsEnvironment {
    if ($env:OS -ne 'Windows_NT') {
        throw 'This installer is intended for Windows only.'
    }

    if (-not [Environment]::Is64BitOperatingSystem) {
        throw 'Elastic Stack requires a supported 64-bit Windows installation.'
    }

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw 'PowerShell 5.1 or newer is required.'
    }
}

function Initialize-InstallRoot {
    param([Parameter(Mandatory)][string]$Path)

    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }

        $testFile = Join-Path $Path ('.write-test-' + [Guid]::NewGuid().ToString('N') + '.tmp')
        [System.IO.File]::WriteAllText($testFile, 'test')
        Remove-Item -LiteralPath $testFile -Force
    }
    catch {
        $fallbackPath = Join-Path $env:USERPROFILE 'Elastic'
        throw "Cannot write to '$Path'. Run PowerShell as Administrator or use -InstallRoot '$fallbackPath'. Details: $($_.Exception.Message)"
    }
}

function Download-File {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$DisplayName
    )

    $destinationDirectory = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    }

    $maximumAttempts = 3

    for ($attempt = 1; $attempt -le $maximumAttempts; $attempt++) {
        try {
            if (Test-Path -LiteralPath $Destination) {
                Remove-Item -LiteralPath $Destination -Force
            }

            Write-Host "Downloading $DisplayName (attempt $attempt/$maximumAttempts)..."

            $bitsCommand = Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue
            if (-not $bitsCommand) {
                try {
                    Import-Module BitsTransfer -ErrorAction Stop
                    $bitsCommand = Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue
                }
                catch {
                    $bitsCommand = $null
                }
            }

            if ($bitsCommand) {
                $bitsParameters = @{
                    Source = $Uri
                    Destination = $Destination
                    DisplayName = $DisplayName
                    Description = "Elastic Stack $Version download"
                    ErrorAction = 'Stop'
                }
                Start-BitsTransfer @bitsParameters
            }
            else {
                $oldProgressPreference = $ProgressPreference
                try {
                    $ProgressPreference = 'SilentlyContinue'
                    Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing -ErrorAction Stop
                }
                finally {
                    $ProgressPreference = $oldProgressPreference
                }
            }

            if (-not (Test-Path -LiteralPath $Destination)) {
                throw 'The download command completed without creating the destination file.'
            }

            if ((Get-Item -LiteralPath $Destination).Length -eq 0) {
                throw 'The downloaded file is empty.'
            }

            Write-Ok "$DisplayName downloaded"
            return
        }
        catch {
            if ($attempt -eq $maximumAttempts) {
                throw "Failed to download '$Uri' after $maximumAttempts attempts. Details: $($_.Exception.Message)"
            }

            Write-Warning "Download failed: $($_.Exception.Message)"
            Start-Sleep -Seconds (3 * $attempt)
        }
    }
}

function Get-ExpectedSha512 {
    param([Parameter(Mandatory)][string]$ChecksumFile)

    $checksumContent = Get-Content -LiteralPath $ChecksumFile -Raw
    $match = [Regex]::Match($checksumContent, '(?i)\b[0-9a-f]{128}\b')

    if (-not $match.Success) {
        throw "No valid SHA-512 checksum was found in '$ChecksumFile'."
    }

    return $match.Value.ToUpperInvariant()
}

function Confirm-Sha512 {
    param(
        [Parameter(Mandatory)][string]$ArchivePath,
        [Parameter(Mandatory)][string]$ChecksumPath
    )

    $expected = Get-ExpectedSha512 -ChecksumFile $ChecksumPath
    $actual = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA512).Hash.ToUpperInvariant()

    if ($actual -ne $expected) {
        throw "SHA-512 verification failed for '$ArchivePath'. Expected $expected but calculated $actual."
    }

    Write-Ok "SHA-512 verified: $(Split-Path -Leaf $ArchivePath)"
}

function Expand-ProductArchive {
    param(
        [Parameter(Mandatory)][string]$ArchivePath,
        [Parameter(Mandatory)][string]$ExpectedFolderName,
        [Parameter(Mandatory)][string]$DestinationPath
    )

    if (Test-Path -LiteralPath $DestinationPath) {
        if (-not $Force) {
            Write-Host "Already installed, skipping extraction: $DestinationPath" -ForegroundColor Yellow
            return
        }

        Write-Warning "Removing existing directory because -Force was specified: $DestinationPath"
        Remove-Item -LiteralPath $DestinationPath -Recurse -Force
    }

    $stagingPath = Join-Path $InstallRoot ('.extract-' + [Guid]::NewGuid().ToString('N'))

    try {
        New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null
        Write-Host "Extracting $(Split-Path -Leaf $ArchivePath)..."
        Expand-Archive -LiteralPath $ArchivePath -DestinationPath $stagingPath -Force

        $expectedSourcePath = Join-Path $stagingPath $ExpectedFolderName
        if (Test-Path -LiteralPath $expectedSourcePath -PathType Container) {
            $sourcePath = $expectedSourcePath
        }
        else {
            $topLevelDirectories = @(Get-ChildItem -LiteralPath $stagingPath -Directory)
            $topLevelFiles = @(Get-ChildItem -LiteralPath $stagingPath -File)

            if (($topLevelDirectories.Count -eq 1) -and ($topLevelFiles.Count -eq 0)) {
                $sourcePath = $topLevelDirectories[0].FullName
            }
            else {
                throw "Unexpected archive layout in '$ArchivePath'."
            }
        }

        Move-Item -LiteralPath $sourcePath -Destination $DestinationPath
        Write-Ok "Installed: $DestinationPath"
    }
    finally {
        if (Test-Path -LiteralPath $stagingPath) {
            Remove-Item -LiteralPath $stagingPath -Recurse -Force
        }
    }
}

function Write-Utf8NoBomFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $parentDirectory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parentDirectory)) {
        New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function New-LauncherScripts {
    param(
        [Parameter(Mandatory)][string]$ElasticsearchHome,
        [Parameter(Mandatory)][string]$KibanaHome,
        [Parameter(Mandatory)][string]$LogstashHome
    )

    $elasticsearchRelative = Split-Path -Leaf $ElasticsearchHome
    $kibanaRelative = Split-Path -Leaf $KibanaHome
    $logstashRelative = Split-Path -Leaf $LogstashHome

    $elasticsearchLauncher = @"
# Start Elasticsearch in the current console.
Set-Location -LiteralPath (Join-Path `$PSScriptRoot '$elasticsearchRelative')
& (Join-Path `$PWD 'bin\elasticsearch.bat')
"@

    $kibanaLauncher = @"
# Start Kibana in the current console. Elasticsearch should already be running.
Set-Location -LiteralPath (Join-Path `$PSScriptRoot '$kibanaRelative')
& (Join-Path `$PWD 'bin\kibana.bat')
"@

    $logstashLauncher = @"
# Start Logstash and pass supplied arguments to logstash.bat.
# Example: .\start-logstash.ps1 -f .\logstash-$Version\pipeline\console-demo.conf
Set-Location -LiteralPath (Join-Path `$PSScriptRoot '$logstashRelative')
& (Join-Path `$PWD 'bin\logstash.bat') @args
"@

    Write-Utf8NoBomFile -Path (Join-Path $InstallRoot 'start-elasticsearch.ps1') -Content $elasticsearchLauncher
    Write-Utf8NoBomFile -Path (Join-Path $InstallRoot 'start-kibana.ps1') -Content $kibanaLauncher
    Write-Utf8NoBomFile -Path (Join-Path $InstallRoot 'start-logstash.ps1') -Content $logstashLauncher

    $demoPipelinePath = Join-Path $LogstashHome 'pipeline\console-demo.conf'
    if (-not (Test-Path -LiteralPath $demoPipelinePath)) {
        $demoPipeline = @'
input {
  stdin { }
}

output {
  stdout {
    codec => rubydebug
  }
}
'@
        Write-Utf8NoBomFile -Path $demoPipelinePath -Content $demoPipeline
    }

    Write-Ok 'Launcher scripts and a console-only Logstash demo pipeline were created'
}

function Write-InstallationManifest {
    param([Parameter(Mandatory)][array]$Products)

    $manifest = [ordered]@{
        installedAt = (Get-Date).ToString('o')
        version = $Version
        installRoot = $InstallRoot
        products = @($Products | ForEach-Object {
            [ordered]@{
                name = $_.Name
                installationPath = $_.DestinationPath
                archiveUrl = $_.ArchiveUrl
                checksumUrl = $_.ChecksumUrl
            }
        })
    }

    $manifestPath = Join-Path $InstallRoot 'elastic-stack-installation.json'
    $json = $manifest | ConvertTo-Json -Depth 5
    Write-Utf8NoBomFile -Path $manifestPath -Content $json
}

Assert-WindowsEnvironment

# Elastic download endpoints require modern TLS.
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}
catch {
    Write-Warning 'Could not explicitly enable TLS 1.2. Continuing with the system default.'
}

$InstallRoot = [System.IO.Path]::GetFullPath($InstallRoot)
Initialize-InstallRoot -Path $InstallRoot

$downloadDirectory = Join-Path $InstallRoot 'downloads'
New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null

$products = @(
    [pscustomobject]@{
        Name = 'Elasticsearch'
        ArchiveName = "elasticsearch-$Version-windows-x86_64.zip"
        ExtractedFolder = "elasticsearch-$Version"
        DestinationPath = Join-Path $InstallRoot "elasticsearch-$Version"
        ArchiveUrl = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$Version-windows-x86_64.zip"
        ChecksumUrl = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$Version-windows-x86_64.zip.sha512"
    }
    [pscustomobject]@{
        Name = 'Kibana'
        ArchiveName = "kibana-$Version-windows-x86_64.zip"
        ExtractedFolder = "kibana-$Version-windows-x86_64"
        DestinationPath = Join-Path $InstallRoot "kibana-$Version-windows-x86_64"
        ArchiveUrl = "https://artifacts.elastic.co/downloads/kibana/kibana-$Version-windows-x86_64.zip"
        ChecksumUrl = "https://artifacts.elastic.co/downloads/kibana/kibana-$Version-windows-x86_64.zip.sha512"
    }
    [pscustomobject]@{
        Name = 'Logstash'
        ArchiveName = "logstash-$Version-windows-x86_64.zip"
        ExtractedFolder = "logstash-$Version"
        DestinationPath = Join-Path $InstallRoot "logstash-$Version"
        ArchiveUrl = "https://artifacts.elastic.co/downloads/logstash/logstash-$Version-windows-x86_64.zip"
        ChecksumUrl = "https://artifacts.elastic.co/downloads/logstash/logstash-$Version-windows-x86_64.zip.sha512"
    }
)

$banner = @"
Elastic Stack Windows Installer
Version      : $Version
Install root : $InstallRoot
Products     : Elasticsearch, Kibana, Logstash
"@
Write-Host $banner -ForegroundColor White

foreach ($product in $products) {
    Write-Step "Processing $($product.Name)"

    $archivePath = Join-Path $downloadDirectory $product.ArchiveName
    $checksumPath = "$archivePath.sha512"
    $alreadyInstalled = Test-Path -LiteralPath $product.DestinationPath -PathType Container

    if ($alreadyInstalled -and (-not $Force)) {
        Write-Host "Existing installation found: $($product.DestinationPath)" -ForegroundColor Yellow
        Write-Host 'Use -Force to replace it.' -ForegroundColor Yellow
        continue
    }

    if ($Force -or (-not (Test-Path -LiteralPath $archivePath))) {
        Download-File -Uri $product.ArchiveUrl -Destination $archivePath -DisplayName "$($product.Name) archive"
    }
    else {
        Write-Host "Using cached archive: $archivePath"
    }

    Download-File -Uri $product.ChecksumUrl -Destination $checksumPath -DisplayName "$($product.Name) checksum"
    Confirm-Sha512 -ArchivePath $archivePath -ChecksumPath $checksumPath

    $expandParameters = @{
        ArchivePath = $archivePath
        ExpectedFolderName = $product.ExtractedFolder
        DestinationPath = $product.DestinationPath
    }
    Expand-ProductArchive @expandParameters
}

Write-Step 'Creating helper files'
$launcherParameters = @{
    ElasticsearchHome = $products[0].DestinationPath
    KibanaHome = $products[1].DestinationPath
    LogstashHome = $products[2].DestinationPath
}
New-LauncherScripts @launcherParameters
Write-InstallationManifest -Products $products

if (-not $KeepArchives) {
    Write-Step 'Removing downloaded archives'
    if (Test-Path -LiteralPath $downloadDirectory) {
        Remove-Item -LiteralPath $downloadDirectory -Recurse -Force
    }
    Write-Ok 'Download cache removed'
}
else {
    Write-Ok "Archives retained in: $downloadDirectory"
}

$completionMessage = @"

Installation completed.

First run order:
  1. Open PowerShell and run:
       Set-Location -LiteralPath '$InstallRoot'
       .\start-elasticsearch.ps1

  2. Save the generated 'elastic' password and Kibana enrollment token.

  3. Open a second PowerShell window and run:
       Set-Location -LiteralPath '$InstallRoot'
       .\start-kibana.ps1

  4. Optional Logstash console demo:
       Set-Location -LiteralPath '$InstallRoot'
       .\start-logstash.ps1 -f '.\logstash-$Version\pipeline\console-demo.conf'

Elasticsearch: https://localhost:9200
Kibana       : http://localhost:5601
"@
Write-Host $completionMessage -ForegroundColor Green