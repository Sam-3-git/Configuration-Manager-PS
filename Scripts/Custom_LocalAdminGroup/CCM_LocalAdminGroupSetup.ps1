###############################################################################
# # Author: Sam                                                             # #
# # Script: CCM_LocalAdminGroupSetup.ps1                                    # #
###############################################################################

<#
    .SYNOPSIS
        Script to setup CI, Baseline, and Custom Hardware Inventory in a SCCM enviorment 
   
    .DESCRIPTION
        Script used to preform a complete setup and initialization of a the custom hardware class CCM_LocalAdminGroupDetails. This class inventories details surrounding the Local Admin Group of targeted devices.
        This script relies on CCM_LocalAdminGroup.mof and CCM_LocalAdminGroupDetails to reside in the same root directory. It is advised that this script is run by an administrator with the 'Full Administrator' 
        role in SCCM. If in a CAS enviorment, please run this at the CAS and not the primary site.
        A new class called CCM_LocalAdminGroupDetails will be added to the default client settings. A new Configuration Item will be added named CCM_LocalAdminGroupDetails. 
        A new Configuration Baseline will be added named CCM_LocalAdminGroupDetails. This Configuration Baseline will be deployed
        to All Desktop and Server Clients unless specefied otherwise.

    .PARAMETER SiteCode
        ConfigMan Site Code. If in a CAS enviorment point to the CAS. 

    .PARAMETER ProviderMachineName
        ConfigMan Site Server FQDN. If in a CAS enviorment point to the CAS. 

    .PARAMETER CMDeviceCollectionName
        Target CMDeviceCollection for baseline deployment. Default is All Desktop and Server Clients

    .EXAMPLE
        # Delply to a CCM collection
        CCM_LocalAdminGroupSetup.ps1 -SiteCode ABC -ProviderMachineName host.domain -CMDeviceCollectionName 'Operating Systems - Windows 10'
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
    [String]$CMDeviceCollectionName='All Desktop and Server Clients'

)



# Site configuration
# $SiteCode = "ABC" # Site code
# $ProviderMachineName = "SITESERVER" # SMS Provider machine name
$SiteCode = $SiteCode # Site code
$ProviderMachineName = $ProviderMachineName # SMS Provider machine name


# CCMizations
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
$Mof = "$PSScriptRoot\CCM_LocalAdminGroup.mof"
$CBCab = "$PSScriptRoot\CCM_LocalAdminGroupDetails.cab"

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
         
        "<![LOG[$Message]LOG]!><time=$([char]34)$Date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$Component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$Severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath "$LogPath\CCM_LocalAdminGroupSetup.log" -Append -NoClobber -Encoding default
}
Write-Log -Message "INFO: $env:USERNAME started script CCM_LocalAdminGroupSetup.ps1" -Severity 1 -Component "START" # Start Log

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
Write-Host "LOG:    $($PSScriptRoot)\CCM_LocalAdminGroupSetup.log" -ForegroundColor DarkGray
Write-Host
Write-Host

# need to verify source files are in path and get content
Write-Host "Checking if required files are present in root directory"
if (Test-Path $Mof) {
    $MofContent = Get-Content -path $Mof
    Write-Log -Message "INFO: Getting $Mof content" -Severity 1 -Component "MAIN"
} else {
    $PSSItem
    Write-Error "Unable to verify $Mof exists"
    Write-Log -Message "ERROR: Getting $Mof content" -Severity 3 -Component "MAIN"   
    Exit-Script 
}
if (Test-Path $CBCab) {

} else {
    $PSSITem
    Write-Error "Unable to verify $CBCab"
    Write-Log -Message "ERROR: Getting $CBCab content" -Severity 3 -Component "MAIN"   
    Exit-Script
}
Write-Host "Success!" -ForegroundColor Green
Write-Host

# Deploy imported baseline to CMDeviceCollectionName: Default all desktop and server clients
Write-Host "Setting up baseline components"
try {
    Write-Host "Importing baseline from source files"
    Import-CMConfigurationItem -FileName $CBCab -Force
    Write-Host "Success!" -ForegroundColor Green
    Write-Host
    Write-Log -Message "INFO: Imported Baseline" -Severity 1 -Component "MAIN"
    Write-Host "Getting Baseline"
    $Baseline = Get-CMBaseline -Fast -Name 'Create WMI Class CCM_LocalAdminGroupDetails'
    Write-Host "Success!" -ForegroundColor Green
    Write-Host
    Write-Log -Message "INFO: Retrieved Baseline" -Severity 1 -Component "MAIN"
    Write-Host "Creating Baseline Schedule"
    $BaselineSchedule = New-CMSchedule -DurationInterval Days -DurationCount 0 -RecurInterval Days -RecurCount 1
    Write-Host "Success!" -ForegroundColor Green
    Write-Host
    Write-Log -Message "INFO: Created Schedule" -Severity 1 -Component "MAIN"
    Write-Host "Deploying baseline to $CMDeviceCollectionName"
    $Baseline | New-CMBaselineDeployment -CollectionName $CMDeviceCollectionName -Schedule $BaselineSchedule | Out-Null  
    Write-Host "Success!" -ForegroundColor Green
    Write-Host
    Write-Log -Message "INFO: Deployed Baseline" -Severity 1 -Component "MAIN"  
}
catch {
    $PSSITem
    Write-Error "Unable to setup baselines"
    Write-Log -Message "ERROR: Unable to setup Baselines" -Severity 3 -Component "MAIN"   
    Exit-Script
}
Write-Host "All baseline components successfull!" -ForegroundColor Green
Write-Host

# no cmndlet way to import mof for client settings. pivoting to wmi methods. Used debug in console to find required info.
# need to add mof file to import class in default settings.
try {
    $WMIArguments = @{
        InventoryReportID = '{00000000-0000-0000-0000-000000000001}'
        ImportType = [uint32]3
        MofBuffer = [string]($MofContent -join "`r`n")
    }
    Invoke-CMWmiMethod -ClassName 'SMS_InventoryReport' -MethodName 'ImportInventoryReport' -Parameter $WMIArguments | Out-Null    
    Write-Log -Message "INFO: Imported MOF to default Client Settings" -Severity 1 -Component "MAIN"
}
catch {
    $PSSITem
    Write-Error "Unable to invoke CM WMI"
    Write-Log -Message "ERROR: Unable to invoke CM WMI" -Severity 3 -Component "MAIN"   
    Exit-Script
}
Write-Host "Success!" -ForegroundColor Green
Write-Host

# return user back to where they started. 
Write-Host "All directeves completed for CCM_LocalAdminGroupSetup."
Exit-Script
