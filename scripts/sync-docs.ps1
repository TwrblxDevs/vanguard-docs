[CmdletBinding()]
param(
	[string]$Source = (Join-Path $PSScriptRoot "..\..\MyFramework\docs")
)

$ErrorActionPreference = "Stop"

$sourceRoot = (Resolve-Path -LiteralPath $Source).Path
$siteRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$siteDocsRoot = Join-Path $siteRoot "docs"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

New-Item -ItemType Directory -Path $siteDocsRoot -Force | Out-Null

$copied = 0
Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter README.md -File | ForEach-Object {
	$relativePath = $_.FullName.Substring($sourceRoot.Length).TrimStart("\", "/")
	$relativeDirectory = Split-Path -Parent $relativePath

	if ([string]::IsNullOrEmpty($relativeDirectory)) {
		$targetPath = Join-Path $siteDocsRoot "index.md"
	} else {
		$targetDirectory = Join-Path $siteDocsRoot $relativeDirectory
		New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
		$targetPath = Join-Path $targetDirectory "index.md"
	}

	$content = Get-Content -LiteralPath $_.FullName -Raw
	$content = $content.Replace("Return to the [project README](../README.md).", "")
	$content = $content.Replace("README.md", "index.md")
	[System.IO.File]::WriteAllText($targetPath, $content, $utf8NoBom)
	$copied += 1
}

Write-Host "Synchronized $copied Vanguard documentation pages from $sourceRoot"
