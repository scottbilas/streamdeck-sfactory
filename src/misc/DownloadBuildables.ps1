#Requires -Version 7
#Requires -Modules PowerHTML

# TODO: extract this from "C:\Program Files (x86)\Steam\steamapps\common\Satisfactory\CommunityResources\Docs\Docs.json"

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$response = Invoke-WebRequest 'https://satisfactory.fandom.com/wiki/Buildings'
$html = ConvertFrom-Html $response

$groupings = [ordered]@{ # order matters here for the matcher
    FICSMAS     = @{ sort = 101; match = 'FICSMAS', 'Candy', 'Snowman' }
    Special     = @{ sort =  99; match = 'AWESOME', 'Elevator', 'HUB', 'MAM' }
    Transport   = @{ sort =  40; match = 'Cyber', 'Explorer', 'Tractor', 'Truck', 'Train', 'Locomotive', 'Car', 'Signal', 'Railway', 'Pad', 'Hypertube' }
    Power       = @{ sort =   2; match = 'Power', 'Generator', 'Outlet' }
    Walls       = @{ sort =  13; match = 'Wall', 'Window', 'Gate' }
    Decorations = @{ sort =  20; match = 'Light', 'Label', 'Billboard', 'Sign', 'Panel', 'Barrier' }
    Walkways    = @{ sort =  12; match = 'Catwalk', 'Walkway', 'Ladder', 'Platform', 'Stairs', 'Railing', 'Lookout' }
    Blocks      = @{ sort =  10; match = 'Foundation', 'Ramp', 'Corner', 'Quarter' }
    Structure   = @{ sort =  11; match = 'Pillar', 'Beam' }
    Roofs       = @{ sort =  14; match = 'Roof' }
    Logistics   = @{ sort =   1; match = 'Conveyor', 'Belt', 'Lift', 'Merger', 'Splitter', 'Pipeline', 'Valve', 'Drone' }
    Other       = @{ sort = 100; match = @() }
}

function match($name) {
    $words = $name -split ' '
    foreach ($grouping in $groupings.GetEnumerator()) {
        foreach ($match in $grouping.Value.match) {
            if ($words -contains $match) {
                return $grouping.Name
            }
        }
    }
    return 'Other'
}

function NameAndVariant($text) {
    $text -match '^(.*?)(?:\s+\((.*?)\))?$' | Out-Null
    $Matches[1], $Matches[2]
}

$images = @{}
Get-ChildItem (Join-Path $PSScriptRoot .. images buildables) | ForEach-Object {
    $name, $variant = NameAndVariant ([IO.Path]::GetFileNameWithoutExtension($_.Name).Replace('_', ' '))

    if (!$images[$name]) {
        $images[$name] = New-List
    }
    if ($variant) {
        $images[$name].Add($variant)
    }
}

$buildables = [ordered]@{}
$groupings.Keys | Sort-Object { $groupings[$_].sort } | ForEach-Object { $buildables[$_] = [ordered]@{} }

$reported = @{}
$html.SelectNodes("(//table[@class='wikitable'])[1]//tr//td[1]") | ForEach-Object {
    # cleanup scraped name
    $_.InnerText.Replace('FICS???MAS', '')
} | Sort-Object | ForEach-Object {
    # split out the variant name if any
    $name, $variant = NameAndVariant $_

    if ($images.ContainsKey($name)) {
        $variants = $images[$name]
        if ($variant) {
            if (!$variants.Remove($variant)) {
                Write-Warning "No image for buildable $name ($variant)"
            }
            if (!$variants.Count) {
                [void]$images.Remove($name)
            }
        }
        else {
            if ($variants.Count) {
                Write-Warning "Multiple images for buildable $name"
            }
            [void]$images.Remove($name)
        }
    }
    elseif (!$reported[$name]) {
        Write-Warning "No images for buildable $name"
        $reported[$name] = 1
    }

    @{ name = $name; variant = $variant }
} | Group-Object name | ForEach-Object {
    $group = $buildables[(match $_.Name)]
    $variants = $_.Group.variant ?? @()

    $group[$_.Name] = $variants.Length -gt 1 ? ($variants | ForEach-Object { $_ ?? "" }) : @()
}

$images.Keys | Sort-Object | ForEach-Object{
    $text = $_
    if ($images.$_) {
        $text += " ($($images.$_ -join ', '))"
    }
    Write-Warning "No buildable for image $text"
}

$buildables | ConvertTo-Json | Out-File (Join-Path $PSScriptRoot .. inspector buildables.json) -Encoding utf8
