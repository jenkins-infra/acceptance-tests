## Fail fast - equivalent of "set -e"
$ErrorActionPreference = 'Stop'

## Uncomment to enable Verbose mode - equivalent of "set -x"
# https://stackoverflow.com/questions/41324882/how-to-run-a-powershell-script-with-verbose-output
# $VerbosePreference="Continue"
#Set-PSDebug -Trace 1

$DefaultLocale="en.US"
$DefaultMavenVersion="3\.8\.6"
$DefaultJDKVersion="11\."

Write-Host "AGENT LABEL $Args[0]"
switch -Regex ($Args[0]) {
    "maven-8-windows" {
        $DefaultLocale="en.US"
        $DefaultMavenVersion="3\.8\.4"
        $DefaultJDKVersion="1\.8"
        Break
    }
    "maven-11-windows" {
        $DefaultLocale="en.US"
        $DefaultMavenVersion="3\.8\.4"
        $DefaultJDKVersion="11\."
        Break
    }
    "maven-windows" {
        $DefaultLocale="en.US"
        $DefaultMavenVersion="3\.8\.4"
        $DefaultJDKVersion="1\.8"
        Break
    }
    "jnlp-maven-8" {
        $DefaultLocale="en.US"
        $DefaultMavenVersion="3\.8\.4"
        $DefaultJDKVersion="1\.8"
        Break
    }
    "jnlp-maven-17" {
        $DefaultLocale="en.US"
        $DefaultMavenVersion="3\.8\.6"
        $DefaultJDKVersion="17\."
        Break
    }
}

[int]$failed=0

Get-Item -Path Env

function Test-IsInsideContainer {
    $foundService = Get-Service -Name cexecsvc -ErrorAction SilentlyContinue
    if( $foundService -eq $null ) {
        $false
    }
    else {
        $true
    }
}

if(Test-IsInsideContainer) {
    Write-Host "Running inside container"
} else {
    Write-Host "NOT running inside container"
}


Get-Item -Path Env:\*PROCESSOR*
Get-Item -Path Env:\OS
Get-Item -Path Env:\USERNAME
$username = Get-Item -Path Env:\USERNAME | Select-Object -ExpandProperty Value
if($username -eq 'jenkins') {
    Write-Host "Running as jenkins user"
} else {
    if(Test-IsInsideContainer) {
        Write-Host "Running inside container"
    } else {
        Write-Host "ERROR Running as $username user"
        $failed=$failed+1
    }
}

try{
    $memoryGB = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb
    Write-Host "MEMORY GB: $memoryGB"
} catch {
    Write-Host "ACCESS TO MEMORY VALUE DENIED"
}

Invoke-Expression -Command "mvn -v"

try{
    $langue = Invoke-Expression -Command "mvn -v" | Select-String -Pattern "Default locale"
    switch -Regex ($langue) {
        $DefaultLocale {"Locale OK $DefaultLocale in $langue"; Break}
        Default {"Error Locale: $langue not matching $DefaultLocale"; $failed=$failed+2; Break}
    }
} catch {
    Write-Host "ACCESS TO locale VALUE DENIED"
}

$javaVersion = Invoke-Expression -Command "mvn -v" | Select-String -Pattern "Java version"
switch -Regex ($javaVersion) {
    '1\.8' {"java  8: $javaVersion";}
    '11\.' {"java 11: $javaVersion";}
    '17\.' {"java 17: $javaVersion";}
    Default {"java inconnu:  $javaVersion"; $failed=$failed+4; Break}
}
if ($javaVersion -match $DefaultJDKVersion) {
    Write-Host "Running with $DefaultJDKVersion ($javaVersion)"
} else {
    Write-Host "ERROR Running with $javaVersion"
    $failed=$failed+8
}

$mavenVersion = Invoke-Expression -Command "mvn -v" | Select-String -Pattern "Apache Maven"
switch -Regex ($mavenVersion) {
    $DefaultMavenVersion {"Maven OK $mavenVersion"; Break}
    Default {"Error Maven:  $mavenVersion"; $failed=$failed+16; Break}
}

exit $failed
