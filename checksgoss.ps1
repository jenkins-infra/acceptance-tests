## Fail fast - equivalent of "set -e"
$ErrorActionPreference = 'Stop'

## Uncomment to enable Verbose mode - equivalent of "set -x"
# https://stackoverflow.com/questions/41324882/how-to-run-a-powershell-script-with-verbose-output
# $VerbosePreference="Continue"
#Set-PSDebug -Trace 1

# Disable Progress bar for faster downloads
$ProgressPreference = 'SilentlyContinue'

$env:GOSS_USE_ALPHA=1
$GOSS_VERSION="0.3.20"

Write-Host "https://github.com/goss-org/goss/releases/download/v${GOSS_VERSION}/goss-alpha-windows-amd64.exe"
Invoke-WebRequest "https://github.com/goss-org/goss/releases/download/v${GOSS_VERSION}/goss-alpha-windows-amd64.exe" -OutFile "C:\\tools\\goss.exe"

Invoke-Command {& goss -g ./goss-windows.yaml validate --format documentation;}
