###############################################################################
# # Author: Sam                                                             # #
# # Script: Custom_LocalAdminGroupSetup.ps1                                 # #
###############################################################################

<#
    .SYNOPSIS
        Script to setup CI, Baseline, and Custom Hardware Inventory in a SCCM enviorment 
   
    .DESCRIPTION
        Script used to preform a complete setup and initialization of a the custom hardware class CCM_LocalAdminGroupDetails. This class inventories details surrounding the Local Admin Group of targeted devices.
        This script relies on Custom_LocalAdminGroup.mof and Custom_LocalAdminGroup.ps1 to reside in the same root directory. It is advised that this script is run by an administrator with the 'Full Administrator' role in SCCM. If in a CAS enviorment, please run this at the CAS and not the primary site.
        A new class called CCM_LocalAdminGroupDetails will be added to the default client settings. A new Configuration Item will be added named CCM_LocalAdminGroupDetails. A new Configuration Baseline will be added named Create - WMIClass_CCM_LocalAdminGroupDetails. This Configuration Baseline will be deployed
        to All Desktop and Server Clients unless specefied otherwise.

    .PARAMETER SiteCode
        ConfigMan Site Code. If in a CAS enviorment point to the CAS. 

    .PARAMETER ProviderMachineName
        ConfigMan Site Server FQDN. If in a CAS enviorment point to the CAS. 

    .PARAMETER CMDeviceCollectionName
        Target CMDeviceCollection for baseline deployment. Default is All Desktop and Server Clients

    .EXAMPLE
        # To Start Script in MENU mode
        SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -Menu
#>

##########
# params #
##########
[CmdletBinding()]
PARAM (
    [Parameter(Mandatory = $true)]
    [String]$SiteCode,

    [Parameter(Mandatory = $true)]
    [String]$ProviderMachineName,

    [Parameter()]
    [String]$CMDeviceCollectionName='All Desktop and Server Clients',

)



# Site configuration
# $SiteCode = "ABC" # Site code
# $ProviderMachineName = "SITESERVER" # SMS Provider machine name
$SiteCode = $SiteCode # Site code
$ProviderMachineName = $ProviderMachineName # SMS Provider machine name


# Customizations
$initParams = @{}
# $initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
# $initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Import the ConfigurationManager.psd1 module
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

########
# VARS #
########
$Mof = "$PSScriptRoot\Custom_LocalAdminGroup.mof"
$CIScript = "$PSScriptRoot\Custom_LocalAdminGroup.ps1"

#############
# Functions #
#############

# Logging Function
##################
Function Write-Log
{
 
    PARAM(
        [String]$Message,
        [int]$Severity,
        [string]$Component
    )
        $LogPath = $PSScriptRoot
        $TimeZoneBias = Get-WMIObject -Query "Select Bias from Win32_TimeZone"
        $Date= Get-Date -Format "HH:mm:ss.fff"
        $Date2= Get-Date -Format "MM-dd-yyyy"
        $Type=1
         
        "<![LOG[$Message]LOG]!><time=$([char]34)$Date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$Component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$Severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath "$LogPath\Custom_LocalAdminGroupSetup.log" -Append -NoClobber -Encoding default
}
Write-Log -Message "INFO: $env:USERNAME started script Custom_LocalAdminGroupSetup.ps1" -Severity 1 -Component "START" # Start Log

# Q) Function Q Exit
####################
Function Exit-Script {
    # Exit
    Write-Host "Exiting..." -ForegroundColor Green
    Write-Log -Message "Exiting..." -Severity 1 -Component "EXIT"
    Set-Location $PSScriptRoot
    return
}

########
# Main #
########
Cls
Write-Host "SITE:   $SiteCode" -ForegroundColor DarkGray
Write-Host "SERVER: $ProviderMachineName" -ForegroundColor DarkGray
Write-Host "USER:   $env:USERNAME" -ForegroundColor DarkGray
Write-Host "LOG:    $($PSScriptRoot)\Custom_LocalAdminGroupSetup.log" -ForegroundColor DarkGray
Write-Host
Write-Host

# need to verify source files are in path and get content
if (Test-Path $Mof) {
    $MofContent = Get-Content -path $Mof
    Write-Log -Message "INFO: Getting $Mof content" -Severity 1 -Component "MAIN"
} else {
    Write-Error "Unable to verify $Mof exists"
    Write-Log -Message "ERROR: Getting $Mof content" -Severity 3 -Component "MAIN"   
    Exit-Script 
}
if (Test-Path $CIScript) {
    $CIScriptContent = Get-Content -path $CIScript
    Write-Log -Message "INFO: Getting $CIScript content" -Severity 1 -Component "MAIN"
} else {
    Write-Error "Unable to verify $CIScript"
    Write-Log -Message "ERROR: Getting $CIScript content" -Severity 3 -Component "MAIN"   
    Exit-Script
}

# create and store CB / CI to set later. 
try {
    New-CMBaseline -Name 'Create - WMIClass_CCM_LocalAdminGroupDetails' -Description "Created by Custom_LocalAdminGroupSEtup.ps1. logs can be found at $PSScriptRoot. Intended to contain only CI CCM_LocalAdminGroupDetails." | Out-Null   
    $CB = Get-CMBaseLine -Name 'Create - WMIClass_CCM_LocalAdminGroupDetails'
    Write-Log -Message "INFO: Created and stored $($CB.LocalizedDisplayName)" -Severity 1 -Component 'MAIN'
}
catch {
    $PSItem
    Write-Error 'Unable to create baselines'
    Write-Log -Message "ERROR: Create baseline" -Severity 3 -Component 'MAIN'
    Exit-Script
}
try {
    New-CMConfigurationItem -CreationType WindowsOS -Name "CCM_LocalAdminGroupDetails" | Out-Null
    $CI = Get-CMConfigurationItem -Name 'CCM_LocalAdminGroupDetails'
    Write-Log -Message "INFO: Created and stored $($CI.LocalizedDisplayName)" -Severity 1 -Component 'MAIN'
}
catch {
    $PSItem
    Write-Error 'Unable to create configuration items'
    Write-Log -Message "ERROR: Create configuration item" -Severity 3 -Component 'MAIN'
    Exit-Script
}

# set all CI and CB settings
try {

}
catch {
    $PSItem
    Write-Error 'Unable to set Config Items and Config Baselines'
    Write-Log -Message "ERROR: Set configuration item or config baseline" -Severity 3 -Component 'MAIN'
    Exit-Script
}