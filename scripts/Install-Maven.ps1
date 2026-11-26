param([string]$Version = '3.10.0')
$ErrorActionPreference = 'Stop'
$zip = Join-Path $env:RUNNER_TEMP "apache-maven-$Version-bin.zip"
$url = "https://archive.apache.org/dist/maven/maven-3/$Version/binaries/apache-maven-$Version-bin.zip"
Invoke-WebRequest -Uri $url -OutFile $zip
$expected = ((Invoke-RestMethod -Uri "$url.sha512").Trim() -split '\s+')[0]
$actual = (Get-FileHash $zip -Algorithm SHA512).Hash
if ($actual -ne $expected) { throw 'Maven SHA-512 mismatch' }
Expand-Archive -Path $zip -DestinationPath $env:RUNNER_TEMP -Force
$homePath = Join-Path $env:RUNNER_TEMP "apache-maven-$Version"
$bin = Join-Path $homePath 'bin'
$bin | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
"MAVEN_HOME=$homePath" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
