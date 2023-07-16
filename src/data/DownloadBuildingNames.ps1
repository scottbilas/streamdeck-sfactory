#Requires -Version 7
#Requires -Modules PowerHTML

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$response = Invoke-WebRequest 'https://satisfactory.fandom.com/wiki/Buildings'
$html = ConvertFrom-Html $response

$html.SelectNodes("(//table[@class='wikitable'])[1]//tr//td[1]") | ForEach-Object {
    $_.InnerText.Replace('FICS???MAS', '')
} | Out-File (Join-Path $PSScriptRoot Buildings.txt) -Encoding utf8
