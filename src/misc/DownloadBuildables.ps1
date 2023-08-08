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

$buildables = [ordered]@{}
$groupings.Keys | Sort-Object { $groupings[$_].sort } | ForEach-Object { $buildables[$_] = [ordered]@{} }

$html.SelectNodes("(//table[@class='wikitable'])[1]//tr//td[1]") | ForEach-Object {
    # cleanup scraped name
    $_.InnerText.Replace('FICS???MAS', '')
} | Sort-Object | ForEach-Object {
    # split out the variant name if any
    $name, $variant = $_ -split ' \('
    @{ name = $name; variant = $variant -replace '\)', '' }
} | Group-Object name | ForEach-Object {
    #if ($_.Name -eq "Catwalk Corner") { Wait-Debugger }

    $group = $buildables[(match $_.Name)]
    $variants = $_.Group.variant

    $group[$_.Name] = $variants.Length -gt 1 ? $variants : @()
}

$buildables | ConvertTo-Json | Out-File (Join-Path $PSScriptRoot .. inspector buildables.json) -Encoding utf8
