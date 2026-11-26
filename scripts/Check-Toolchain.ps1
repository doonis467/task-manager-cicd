param(
    [int]$RequiredJava = 21,
    [string]$RequiredMaven = '3.10.0',
    [switch]$JavaOnly
)
$ErrorActionPreference = 'Stop'
# Read the specification version, not a substring of the vendor banner.
$ErrorActionPreference = 'Continue'
$javaInfo = (& java -XshowSettings:properties -version 2>&1 | Out-String)
$javaExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($javaExit -ne 0) { throw 'Java command failed' }
if ($javaInfo -notmatch '(?m)^\s*java\.specification\.version\s*=\s*(\S+)\s*$') { throw 'Cannot determine Java version' }
$actualJava = $Matches[1]
Write-Host "Java: $actualJava; required: $RequiredJava"
if ($actualJava -ne "$RequiredJava") { throw "Java version mismatch: expected $RequiredJava, got $actualJava" }
if (-not $JavaOnly) {
    $mavenInfo = (& mvn -B -ntp -version 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) { throw 'Maven command failed' }
    $mavenInfo = $mavenInfo -replace '\x1b\[[0-9;]*m', ''
    if ($mavenInfo -notmatch 'Apache Maven\s+([^\s]+)') { throw 'Cannot determine Maven version' }
    $actualMaven = $Matches[1]
    Write-Host "Maven: $actualMaven; required: $RequiredMaven"
    if ($actualMaven -ne $RequiredMaven) { throw "Maven version mismatch: expected $RequiredMaven, got $actualMaven" }
    if ($mavenInfo -notmatch 'Java version:\s*(\d+)(?:[.,\s-]|$)') { throw 'Cannot determine Maven JVM version' }
    if ($Matches[1] -ne "$RequiredJava") { throw 'Maven runs with an incompatible JVM' }
}
Write-Host 'Toolchain check passed.'
