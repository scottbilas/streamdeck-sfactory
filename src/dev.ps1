#Requires -Version 7

param (
    [switch]$Verbose,
    [switch]$Release,
    [switch]$Publish,
    [switch]$NoBuild,
    [switch]$NoSymlink,
    [switch]$NoTail,
    [switch]$NoDeploy,
    [switch]$DebugInBrowser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$VerbosePreference = $Verbose ? 'Continue' : 'SilentlyContinue'

# specified config

$pluginName = 'StreamDeckSfactory'

# detected config

$buildConfig = $Release ? 'Release' : 'Debug'
$buildDir = Join-Path $PSScriptRoot .. artifacts ($Publish ? 'publish' : 'bin') $buildConfig

# optionally build

if (!$NoBuild) {
    Write-Host "Building $pluginName..."
    dotnet ($Publish ? 'publish' : 'build') (Resolve-Path (Join-Path $PSScriptRoot "$pluginName.csproj")) `
        -c $buildConfig --verbosity quiet -- /nologo /clp:NoSummary
    if ($LASTEXITCODE) {
        Write-Error "Build failed"
    }
}

if (!(Test-Path $buildDir)) {
    Write-Error "Build output dir ('$buildDir') not found; run a build"
}

# stop here if we're not going to deploy

if ($NoDeploy) {
    return
}

# find where we need to deploy to

$streamdeckDir = "$($Env:APPDATA)\Elgato\StreamDeck"
$manifest = Get-Content (Join-Path $buildDir manifest.json) | ConvertFrom-Json
$firstActionUuid = $manifest.Actions[0].UUID
$pluginID = ($firstActionUuid -split '\.' | Select-Object -SkipLast 1) -join '.'
$pluginDir = Join-Path $streamdeckDir Plugins "$pluginID.sdPlugin"

# kill any processes right now so we can delete the plugin folder

Get-Process -Name StreamDeck, $pluginName -ErrorAction SilentlyContinue | Stop-Process -Verbose:$Verbose –Force -ErrorAction SilentlyContinue

# delete the plugin folder for re-deployment

if (Test-Path $pluginDir) {
    Write-Host "Removing old plugin..."
    for ($iter = 0;; ++$iter) {
        if ($iter -gt 10) {
            Remove-Item -Recurse -Force -Path $pluginDir
            break
        }

        Remove-Item -ea:silent -Recurse -Force -Path $pluginDir
        if (!(Test-Path $pluginDir)) { break }
        Start-Sleep .5
    }
}

# deploy

New-Item -Type Directory -Path $pluginDir -ErrorAction SilentlyContinue | Out-Null

if ($NoSymlink) {
    Write-Verbose "Copying items from $buildDir to $pluginDir (full copy, no symlinks)"
    Copy-Item -Path $buildDir\* -Destination $pluginDir -Recurse | Out-Null
}
else {
    Write-Verbose "Copying items from $buildDir to $pluginDir (with symlinks)"
    Copy-Item -Path $buildDir\* -Destination $pluginDir | Out-Null

    'images', 'inspector' | ForEach-Object {
        New-Item -Verbose:$Verbose -ItemType SymbolicLink -Path $pluginDir\$_ -Target $PSScriptRoot\$_ -Force | Out-Null
    }
}

# ensure debugging is enabled before we start the app

if ($DebugInBrowser) {
    New-ItemProperty -Verbose:$Verbose -Force 'HKCU:\Software\Elgato Systems GmbH\StreamDeck' html_remote_debugging_enabled -Value 1 | Out-Null
}

# restart Stream Deck

$start = Get-date

Write-Host 'Restarting StreamDeck app...'
Start-Process -Verbose:$Verbose (Join-Path $Env:ProgramFiles Elgato StreamDeck StreamDeck.exe)

# open debugger

if ($DebugInBrowser) {
    Start-Process -Verbose:$Verbose http://localhost:23654/
}

# tail logfile

if (!$NoTail) {
    Write-Host 'Waiting for log file...'

    for (;;) {
        $logFile = Get-ChildItem -ea:silent (Join-Path $streamdeckDir logs) -Filter com.scottbilas.sfactory*.log |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($logFile -and $logFile.LastWriteTime.Date -ge (Get-Date).Date) {
            break
        }
        Start-Sleep -Seconds .5
    }

    Write-Host "Monitoring $($logFile)..."
    Write-Host

    $first = $true
    $last = $null

    tail -f $logFile | ForEach-Object {
        $parts = $_.Split(' ', 3)

        try {
            $time = [datetime]($parts[0]+' '+$parts[1])
            $last = $time
        }
        catch {
            $time = $last
        }

        if ($time) {
            $offset = ($time - $start).TotalSeconds

            if ($offset -ge 0) {
                if ($first) {
                    $start = Get-Date
                    $offset = 0
                    $first = $false
                }

                Write-Host ("{0,7:0.000} {1}" -f $offset, $parts[2])
            }
        }
    }
}
