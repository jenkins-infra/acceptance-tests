#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$DefaultLocale = 'en-US'
$DefaultMavenVersion = '3.9.12'
$DefaultJDKVersion = 'jdk-21'
$DefaultUser = 'jenkins'

# Allow Mark Waite to run the same script on his home network
if ($env:JENKINS_ADVERTISED_HOSTNAME) {
    $DefaultUser = 'jagent'
}

$failed = 0
$label = ''

if ($args.Count -ge 1 -and $args[0]) {
    $label = $args[0]
    Write-Host "label of the node: $label"
}

# System information
Get-ComputerInfo | Out-String
Get-CimInstance Win32_Processor | Out-String

# Default locale check
$currentCulture = [System.Globalization.CultureInfo]::CurrentCulture.Name
if ($currentCulture -eq $DefaultLocale) {
    Write-Host "$DefaultLocale locale is available"
}
else {
    Write-Host "ERROR: $DefaultLocale locale is not available (current: $currentCulture)"
    $failed += 1
}

# User existence check
try {
    Get-LocalUser -Name $DefaultUser -ErrorAction Stop | Out-Null
    Write-Host "'$DefaultUser' user exists"
}
catch {
    Write-Host "ERROR: '$DefaultUser' user does not exist"
    $failed += 2
}

# Running user check
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
if ($currentUser -notmatch "\\$DefaultUser$") {
    Write-Host "ERROR: Not running as '$DefaultUser' user"
    Write-Host "[System.Security.Principal.WindowsIdentity]::GetCurrent().Name: $currentUser"
    $failed += 4
}

# Administrator privilege check (should NOT be admin)
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: running as Administrator should not be possible"
    $failed += 8
}

# JAVA_HOME check
if (-not $env:JAVA_HOME) {
    Write-Host "ERROR: the 'JAVA_HOME' environment variable is undefined"
    $failed += 16
}

# Maven CLI check
try {
    mvn -v | Out-Null
}
catch {
    Write-Host "ERROR: command 'mvn -v' failed to execute. Debugging informations below:"
    Write-Host $env:PATH
    Get-Command mvn -ErrorAction SilentlyContinue
    mvn -v
    $failed += 32
}

# Label-based JDK validation
if ($label) {
    $jdk = $DefaultJDKVersion

    switch -Wildcard ($label) {
        { $_ -like '*maven-8' -or $_ -like '*jdk-8' -or $_ -like '*maven8' } {
            $jdk = 'jdk-8'
        }
        { $_ -like '*maven-11' -or $_ -like '*jdk-11' -or $_ -like '*maven11' } {
            $jdk = 'jdk-11'
        }
        { $_ -like '*maven-17' -or $_ -like '*jdk-17' -or $_ -like '*maven17' } {
            $jdk = 'jdk-17'
        }
        { $_ -like '*maven-21' -or $_ -like '*jdk-21' -or $_ -like '*maven21' } {
            $jdk = 'jdk-21'
        }
        { $_ -like '*maven-25' -or $_ -like '*jdk-25' -or $_ -like '*maven25' } {
            $jdk = 'jdk-25'
        }
        default {
            Write-Host "Label '$label' specified. Using default jdk."
        }
    }

    switch ($jdk) {
        'jdk-8' { $jdknumber = '1.8' }
        'jdk-11' { $jdknumber = '11.' }
        'jdk-17' { $jdknumber = '17.' }
        'jdk-21' { $jdknumber = '21' }
        'jdk-25' { $jdknumber = '25' }
        default {
            Write-Host "ERROR: JDK not matching the expected $jdk for label '$label'"
            mvn -v
            $failed += 64
            $jdknumber = $null
        }
    }

    if ($jdknumber) {
        $mvnOutput = mvn -v 2>&1
        $javaLine = $mvnOutput | Select-String 'Java version'
        $jdkFromMaven = $javaLine.ToString().Split(' ')[2]

        if ($jdkFromMaven -notmatch [regex]::Escape($jdknumber)) {
            Write-Host "ERROR: JDK from maven $jdkFromMaven not matching the expected $jdknumber for label '$label'"
            $failed += 64
        }
        else {
            Write-Host "JDK Version ok $jdkFromMaven for $label"
        }
    }
}

# Maven version check
$mvnOutput = mvn -v 2>&1
if ($mvnOutput -notmatch [regex]::Escape($DefaultMavenVersion)) {
    Write-Host "ERROR Maven version not matching what is expected : expecting $DefaultMavenVersion for label '$($args[0])' found $mvnOutput"
    $failed += 128
}
else {
    Write-Host "Maven version $DefaultMavenVersion OK for label '$($args[0])'"
}

# Windows version check
if ($label) {
    $labelVersion = $label -replace '\D'
    $agentVersion = Get-ComputerInfo | Select-Object WindowsProductName -replace '\D'
    if ($labelVersion -eq $agentVersion) {
        Write-Host "Windows $agentVersion version from Get-ComputerInfo matches Windows version from label $label"
    }
    else {
        Write-Host "ERROR: Windows $agentVersion version from Get-ComputerInfo does not match Windows version from label $label"
        $failed += 256
    }
}

exit $failed
