#!/usr/bin/env pwsh
# Note: this script is not compatible with PowerShell 5

[CmdletBinding()]
Param(
    [Parameter(Position = 0)]
    [String] $Label
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$failed = 0
$expectedDefaults = @{
    locale         = 'en-US'
    mavenVersion   = '3.9.16'
    jdkVersion     = 21
    windowsVersion = 2025
    user           = 'jenkins'
}

# Optional checks to perform
[Flags()]
enum OptionalCheck {
    None   = 0
    Jdk    = 1
    Maven  = 2
    Admin  = 4
    Docker = 8
}

# Default optional checks
$optionalChecks = [OptionalCheck]::Jdk -bor [OptionalCheck]::Maven -bor [OptionalCheck]::Admin
switch ($Label) {
    { $_ -like '*docker*' } {
        $optionalChecks = $optionalChecks -bor [OptionalCheck]::Docker
    }
    { $_ -like 'windows*' } {
        $optionalChecks = $optionalChecks -bor [OptionalCheck]::Docker
    }
}
# Exceptions for trusted.ci.jenkins.io agents
if ($env:JENKINS_URL -eq 'https://trusted.ci.jenkins.io/') {
    # Windows agents currently run as Administrator
    $optionalChecks = $optionalChecks -band (-bnot [OptionalCheck]::Admin)
    switch ($Label) {
        { $_ -like 'docker' } {
            # Default JDK not as expected
            $optionalChecks = $optionalChecks -band (-bnot [OptionalCheck]::Jdk)
        }
    }
}

# Exceptions for cert.ci.jenkins.io agents
if ($env:JENKINS_URL -eq 'https://cert.ci.jenkins.io/') {
    # Windows agents currently run as Administrator
    $optionalChecks = $optionalChecks -band (-bnot [OptionalCheck]::Admin)
}

# Exceptions for infra.ci.jenkins.io agents
if ($env:JENKINS_URL -eq 'https://infra.ci.jenkins.io/') {
    # Windows agents currently run as Administrator
    $optionalChecks = $optionalChecks -band (-bnot [OptionalCheck]::Admin)
    # Windows agents are not building or running any java code
    $optionalChecks = $optionalChecks -band (-bnot [OptionalCheck]::Jdk)
    $optionalChecks = $optionalChecks -band (-bnot [OptionalCheck]::Maven)
}

# Allow Mark Waite to run the same script on his home network
if ($env:JENKINS_ADVERTISED_HOSTNAME) {
    $expectedDefaults.user = 'jagent'
}

Write-Host "INFO: Label passed in parameter: $Label"
Write-Host "INFO: expected default values below"
Write-Host ($expectedDefaults | Out-String)
Write-Host "INFO: Optional checks enabled: $optionalChecks"

# System information
$computerInfo = (Get-ComputerInfo)
Write-Host "INFO: system information below"
Write-Host ($computerInfo | Out-String)
try {
    Get-CimInstance Win32_Processor | Out-String
}
catch {
    Write-Host "INFO: not enought permissions for calling 'Get-CimInstance Win32_Processor'"
}

# Default locale check
$currentCulture = [System.Globalization.CultureInfo]::CurrentCulture.Name
if ($currentCulture -eq $expectedDefaults.locale) {
    Write-Host ('INFO: "{0}" is the expected locale' -f $currentCulture)
}
else {
    Write-Host ('ERROR: "{0}" is not the expected "{1}" locale' -f $currentCulture, $expectedDefaults.locale)
    $failed += 1
}

# User existence check
try {
    Get-LocalUser -Name $expectedDefaults.user -ErrorAction Stop | Out-Null
    Write-Host ('INFO: "{0}" user exists' -f $expectedDefaults.user)
}
catch {
    Write-Host ('ERROR: "{0}" does not exist' -f $expectedDefaults.user)
    $failed += 2
}

# Running user check
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
if ($currentUser -match $expectedDefaults.user) {
    Write-Host ('INFO: Running as "{0}" user' -f $expectedDefaults.user)
}
else {
    Write-Host ('ERROR: Not running as "{0}" user' -f $expectedDefaults.user)
    Write-Host ('[System.Security.Principal.WindowsIdentity]::GetCurrent().Name: {0}' -f $currentUser)
    $failed += 4
}

# Administrator privilege check (should NOT be admin)
if ($optionalChecks.HasFlag([OptionalCheck]::Admin)) {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host 'ERROR: Running as Administrator is not expected'
        $failed += 8
    }
    else {
        Write-Host 'INFO: Not running as Administrator as expected'
    }
} else {
    Write-Host 'WARNING: Running as Administrator check skipped'
}

# JAVA_HOME check
if ($optionalChecks.HasFlag([OptionalCheck]::Jdk)) {
    if (-not $env:JAVA_HOME) {
        Write-Host 'ERROR: JAVA_HOME environment variable is undefined'
        $failed += 16
    }
    else {
        Write-Host ('INFO: JAVA_HOME environment variable is defined: {0}' -f $env:JAVA_HOME)
    }
}

# Maven CLI check
$mavenPresent = $false
if ($optionalChecks.HasFlag([OptionalCheck]::Maven)) {
    $mvnOutput = ''
    try {
        $mvnOutput = (mvn -v 2>&1) | Out-String
        $mavenPresent = $true
    }
    catch {
        Write-Host 'ERROR: "mvn -v" command failed to execute. Debugging informations below:'
        Write-Host $env:PATH
        Get-Command mvn -ErrorAction SilentlyContinue
        $mvnOutput = (mvn -v) | Out-String
        Write-Host $mvnOutput
        $failed += 32
    }
} else {
    Write-Host 'WARNING: "mvn -v" check skipped'
}

# Label-based JDK validation
if ($optionalChecks.HasFlag([OptionalCheck]::Jdk)) {
    if ($Label -and -not $Label.StartsWith('windows') -and $mavenPresent) {
        $jdk = $expectedDefaults.jdkVersion

        switch -Wildcard ($Label) {
            { $_ -like '*maven-8*' -or $_ -like '*jdk-8*' -or $_ -like '*maven8*' } {
                $jdk = 8
            }
            { $_ -like '*maven-11*' -or $_ -like '*jdk-11*' -or $_ -like '*maven11*' } {
                $jdk = 11
            }
            { $_ -like '*maven-17*' -or $_ -like '*jdk-17*' -or $_ -like '*maven17*' } {
                $jdk = 17
            }
            { $_ -like '*maven-21*' -or $_ -like '*jdk-21*' -or $_ -like '*maven21*' } {
                $jdk = 21
            }
            { $_ -like '*maven-25*' -or $_ -like '*jdk-25*' -or $_ -like '*maven25*' } {
                $jdk = 25
            }
            default {
                Write-Host ('INFO: "{0}" label does not contain any JDK version. Using default jdk {1}' -f $Label, $jdk)
            }
        }

        switch ($jdk) {
            8  { $jdkVersion = '1.8' }
            11 { $jdkVersion = '11' }
            17 { $jdkVersion = '17' }
            21 { $jdkVersion = '21' }
            25 { $jdkVersion = '25' }
            default {
                Write-Host ('ERROR: JDK{0} does not match the "{1}" label' -f $jdk, $Label)
                mvn -v
                $failed += 64
                $jdkVersion = $null
            }
        }

        if ($jdkVersion) {
            $jdkFromMaven = ''
            $javaLine = (mvn -v 2>&1 | Select-String 'Java version').Line -replace ',', ''
            if ($javaLine -match 'Java version:\s*([^\s,]+)') {
                $jdkFromMaven = $Matches[1]
            }

            if ($jdkFromMaven -and $jdkFromMaven -match [regex]::Escape($jdkVersion)) {
                Write-Host ('INFO: Java version {0} from Maven matches expected JDK{1} from "{2}" label' -f $jdkFromMaven, $jdkVersion, $Label)
            }
            else {
                Write-Host ('ERROR: Java version {0} from Maven does not match expected JDK{1} from "{2}" label' -f $jdkFromMaven, $jdkVersion, $Label)
                $failed += 64
            }
        }
    }
} else {
    Write-Host 'WARNING: Expected JDK check skipped'
}

# Maven version check
if ($optionalChecks.HasFlag([OptionalCheck]::Maven)) {
    if ($mavenPresent -and $mvnOutput -match [regex]::Escape($expectedDefaults.mavenVersion)) {
        Write-Host ('INFO: Maven output match the expected {0} version from "{1}" label:' -f $expectedDefaults.mavenVersion, $Label)
        Write-Host $mvnOutput
    }
    else {
        Write-Host ('ERROR: Maven output does not match the expected {0} version from "{1}" label:' -f $expectedDefaults.mavenVersion, $Label)
        Write-Host $mvnOutput
        $failed += 128
    }
} else {
    Write-Host 'WARNING: Expected Maven output check skipped'
}

# Windows version check
if ($Label) {
    $LabelVersion = $Label -replace '\D'
    $agentVersion = $computerInfo.WindowsProductName -replace '\D'
    if ($LabelVersion.length -eq 4) {
        if ($agentVersion -eq $LabelVersion) {
            Write-Host ('INFO: Windows {0} version from Get-ComputerInfo matches Windows version from "{1}" label' -f $agentVersion, $Label)
        }
        else {
            Write-Host ('ERROR: Windows {0} version from Get-ComputerInfo does not match Windows version from "{1}" label' -f $agentVersion, $Label)
            $failed += 256
        }
    }
    else {
        if ($agentVersion -eq $expectedDefaults.windowsVersion) {
            Write-Host ('INFO: Windows {0} version from Get-ComputerInfo matches default Windows {1} version' -f $agentVersion, $expectedDefaults.windowsVersion)
        }
        else {
            Write-Host ('ERROR: Windows {0} version from Get-ComputerInfo does not match default Windows {1} version' -f $agentVersion, $expectedDefaults.windowsVersion)
            $failed += 256
        }
    }
}

# Docker checks
if ($optionalChecks.HasFlag([OptionalCheck]::Docker)) {
    try {
        $dockerInfo = (docker info) | Out-String
        Write-Host ('INFO: docker is present as expected from "{0}" label, info below' -f $Label)
        Write-Host $dockerInfo
    }
    catch {
        Write-Host ('ERROR: docker is not present as expected from "{0}" label, debugging informations below' -f $Label)
        Write-Host $env:PATH
        Get-Command docker -ErrorAction SilentlyContinue
        $dockerInfo = (docker info) | Out-String
        $failed += 1024
    }
    try {
        $dockerBuildxInspect = (docker buildx inspect) | Out-String
        Write-Host ('INFO: docker buildx is present as expected from "{0}" label, see the result of "docker buildx inspect" below:' -f $Label)
        Write-Host $dockerBuildxInspect
    }
    catch {
        Write-Host ('ERROR: docker buildx is not present as expected from "{0}" label, debugging informations below' -f $Label)
        Write-Host $env:PATH
        Get-Command docker -ErrorAction SilentlyContinue
        $dockerInfo = (docker buildx inspect) | Out-String
        $failed += 2048
    }
} else {
    Write-Host 'WARNING: Docker checks skipped'
}

exit $failed
