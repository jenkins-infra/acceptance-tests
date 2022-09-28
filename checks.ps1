## Fail fast - equivalent of "set -e"
$ErrorActionPreference = 'Stop'

## Uncomment to enable Verbose mode - equivalent of "set -x"
# https://stackoverflow.com/questions/41324882/how-to-run-a-powershell-script-with-verbose-output
# $VerbosePreference="Continue"
Set-PSDebug -Trace 1

function Test-Administrator
{
    [OutputType([bool])]
    param()
    process {
        [Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent();
        return $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
    }
}

Get-Item -Path Env:\*PROCESSOR*
Get-Item -Path Env:\OS
Get-Item -Path Env:\USERNAME

Get-WmiObject -Class win32_computersystem |
    Select-Object -Property @{
        label= 'Total Physical Memory'
        expression={($_.TotalPhysicalMemory/1GB).ToString("N2") + " GB"}
    }

Get-WinSystemLocale | Select-Object -Property Name, DisplayName

if(Test-Administrator)
{
    Write-Error "This script is executed as Administrator.";
    exit 1;
}

#Get-WmiObject -Class Win32_Product -Filter "Name like 'Java(TM)%'" | Select -Expand Version

Invoke-Expression -Command "mvn.exe --version"


#$lastExitCode | Should -Be 0
# Invoke-Expression -Command "mvn.exe --version" -ErrorAction SilentlyContinue |
#     Select-String -Pattern 'Apache Maven'

# Invoke-Expression -Command "java.exe -version" -ErrorAction SilentlyContinue |
#     Select-String -Pattern 'java version'
