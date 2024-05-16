###############################################################################
# # Author: Sam                                                             # #
# # Script: SUG-Toolbox.ps1                                                 # #
# # Date:   01/16/2024                                                      # #
# # Goal:   To complete various tasks when working with SUGs                # #
# # Version: 2.5                                                            # #
###############################################################################

<#
    .SYNOPSIS
        Script to complete various repetitive jobs when working with Software Update Groups.  
   
    .DESCRIPTION
        Script used to preform Creation, Modification, and Removal of Software Update Groups.Contains a small menu to allow configurations not passed using paramaters.-Menu will be the last run paramater. It is possible to call other parameters first, then start the menu to run other tasks. The order of operations are CreateSUG, TargetSUG, SourceSUG, RemoveAllUpdates, DeleteSUG, Menu.  

    .PARAMETER SiteCode
        ConfigMan Site Code

    .PARAMETER ProviderMachineName
        ConfigMan Site Server FQDN

    .PARAMETER Menu
        Whether to run in menu mode. Menu mode allows the user to make selections based on input versus paramater mode where desired configurations are passed. Menu can be called to start the SUG Toolbox menu with any other parameters defined

    .PARAMETER CreateSUG
        Specify a SUG name to create an empty SUG. CreateSUG is also available in MENU mode. Only One SUG can be created at a time with this paramater

    .PARAMETER TargetSUG
        Specify SUG name(s) to target update membership. Target SUG(s) will be populated with any updates found in the SourceSUG(s). TargetSUG will only work with SourceSUG also defined.

    .PARAMETER SourceSUG
        Specify SUG name(s) to get update membership from. The Source SUG(s) will have their update membership scanned. Any updates found will be populated into the Target SUG. SourceSUG will only work when TargetSUG is also defined.
   
    .PARAMETER RemoveAllUpdates
        Specify SUG name(s) to Remove All Update Membersip. The passed SUG(s) will have all current update membership removed.  

    .PARAMETER DeleteSUG
        Specify SUG name(s) to Delete. The passed SUG(s) will be removed.  

    .EXAMPLE
        # To Start Script in MENU mode
        SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -Menu
   
    .EXAMPLE
        # To Create a new empty SUG
        SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -CreateSUG "Example SUG01"

    .EXAMPLE
        # To Create a new empty SUG then start MENU mode
        SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -CreateSUG "Example SUG01" -Menu

    .EXAMPLE
        # To create update membership on a Target SUG that is definded in a Source SUG
        SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -TargetSUG "No Membership SUG01" -SourceSUG "Many Update Membership SUG01"

    .EXAMPLE
        # To create update membership on a newely created Target SUG that is definded in multiple Source SUG(s).
        SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -CreateSUG "New SUG01" -TargetSUG "New SUG01" -SourceSUG "Many Update Membership SUG01","Many Update Membership SUG02"
   
    .EXAMPLE
        # To Remove all updates from SUG(s).
        SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -RemoveAllUpdates "Many Update Membership SUG01","Many Update Membership SUG02"

    .EXAMPLE
        # To Delete SUG(s).
        SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -DeleteSUG "Old SUG01","Old SUG02"

    .EXAMPLE
        # To do all operations.
        SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -CreateSUG "New SUG01" -TargetSUG "New SUG01" -SourceSUG "Old SUG01","Old SUG02" -RemoveAllUpdates "Old SUG01" -DeleteSUG "OldSUG02" -Menu
 
#>

# params
########
[CmdletBinding()]
PARAM (
    [Parameter(Mandatory = $true)]
    [String]$SiteCode,

    [Parameter(Mandatory = $true)]
    [String]$ProviderMachineName,

    [Parameter()]
    [Switch]$Menu,

    [Parameter()]
    [String]$CreateSUG,

    [Parameter()]
    [String[]]$TargetSUG,

    [Parameter()]
    [String[]]$SourceSUG,

    [Parameter()]
    [String[]]$RemoveAllUpdates,

    [Parameter()]
    [String[]]$DeleteSUG

)
########

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

# Variables
###########
$host.privatedata.ProgressForegroundColor = "Cyan"
$host.privatedata.ProgressBackgroundColor = "Black"

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
         
        "<![LOG[$Message]LOG]!><time=$([char]34)$Date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$Component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$Severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath "$LogPath\SUGToolBox.log" -Append -NoClobber -Encoding default
}
##################
Write-Log -Message "$env:USERNAME started script SUG-Toolbox" -Severity 1 -Component "START" # Start Log

# Main Menu
###########
Function Show-Menu {
    Cls
    Write-Host "SITE:   $SiteCode" -ForegroundColor DarkGray
    Write-Host "SERVER: $ProviderMachineName" -ForegroundColor DarkGray
    Write-Host "USER:   $env:USERNAME" -ForegroundColor DarkGray
    Write-Host "LOG:    $($PSScriptRoot)\SUGToolBox.log" -ForegroundColor DarkGray
    Write-Host
    Write-Host
    Write-Host "        ==+=====================================+==" -ForegroundColor Cyan
    Write-Host "          |             SUG ToolBox             |" -foregroundColor Cyan
    Write-Host "        ==+=====================================+==" -ForegroundColor Cyan
    Write-Host "          |  1.)  Create New SUG                |"
    Write-Host "          |  2.)  Transfer SUG Membership(s)    |"
    Write-Host "          |  3.)  Remove Updates From SUG       |"
    Write-Host "          |  4.)  Delete SUG                    |"
    Write-Host "          |       ---------------------         |"
    Write-Host "          |  Q.)  Exit                          |"
    Write-Host "         =+=====================================+=" -ForegroundColor Cyan
    Write-Host "          |             SUG ToolBox             |" -ForegroundColor Cyan
    Write-Host "         =+=====================================+=" -ForegroundColor Cyan
    Write-Host
    Write-Host
    }
###########

# 1) Function One Create-SUG
############################
Function Create-SUG {
    PARAM(
        [String]$NewSUGName
    )
        try {
            if (!$NewSUGName) {
                $NewSUGName = Read-Host "SUG Name:"
            }
            Write-Progress -Activity "Creating $NewSUGName"
            $NewSugDescription = "Created by $env:USERNAME using $($PSScriptRoot)\SUG-Toolbox.ps1"
            New-CMSoftwareUpdateGroup -Name $NewSUGName -Description $NEWSUGDescription | Out-Null
            Write-Progress -Activity "Creating $NewSUGName" -Completed
            Write-Log -Message "Created $NewSUGName" -Severity 1 -Component "Create-SUG"
        }
        Catch {
            Write Warning "$_.Exception.Message"
            Write-Log -Message "$_.Exception.Message" -Severity 3 -Component "Create-SUG"
        }
}
############################

# 2) Function Two Transfer-SUGMemberships
#########################################
Function Transfer-SUGMemberships {
   PARAM(
    [String[]]$TargetSUG,
    [String[]]$SourceSUG
   )
    $SUGCount = 0
    try {
        if (!$TargetSUG) {
            Write-Log -Message "Getting user input for Target SUG" -Severity 1 -Component "Transfer SUG Membership Pre LOOP"
            Write-Host "Choose a Target SUG to transfer updates to" -ForegroundColor Yellow
            $TargetSUG = Get-SUGList -Title "Target SUG(s) to transfer updates to"
        }
        if (!$SourceSUG) {
            Write-Log -Message "Getting user input for Source SUG" -Severity 1 -Component "Transfer SUG Membership Pre LOOP"
            Write-Host "Choose a Source SUG to copy updates from" -ForegroundColor Yellow
            $SourceSUG = Get-SUGList -Title "Source SUG(s) to copy updates from"  
        }
        Write-Log -Message "Target SUG(s): $TargetSUG" -Severity 1 -Component "Transfer SUG Membership Pre LOOP"
        Write-Host "$env:USERNAME selected Target SUG(s): $TargetSUG" -ForegroundColor Green
        Write-Log -Message "Source SUG(s): $SourceSUG" -Severity 1 -Component "Transfer SUG Membership Pre LOOP"
        Write-Host "$env:USERNAME selected Source SUG(s): $SourceSUG" -ForegroundColor Green
        Foreach ($SUG in $SourceSUG) {
            Write-Log -Message "Retrieving Updates from SUG(s): $SUG" -Severity 1 -Component "Transfer SUG Membership Updates"
            Write-Host "Retrieving Updates from SUG(s): $SUG ..." -ForegroundColor Yellow
            $Updates = Get-SUGUpdates -SourceSUG $SUG  
            Write-Log -Message "Retrieved Updates COMPLETED for SUG(s): $SUG" -Severity 1 -Component "Transfer SUG Membership Updates"
            Write-Host "Updates Collected from $SUG" -ForegroundColor Green
            $SUGCount++
            try {
                Write-Progress -Activity "Transfering SUG(s) update membership(s)" -Status "Processing SUG $SUGCount / $($SourceSUG.count)..." -Id 1 -PercentComplete ($SUGCount / $($SourceSUG.count) * 100) -CurrentOperation "Transfering Updates from Source SUG(s): $SUG to Target SUG(s): $TargetSUG"
                Write-Log -Message "Processing Source SUG $SUG" -Severity 1 -Component "Source SUG Processing"
                Write-Host # Spacing
                Write-Host "------ Start $SUG -----" -ForegroundColor Gray
                Write-Host # Spacing
                $Updates | ForEach-Object -Begin {
                    $UpdateCount = 0
                } -Process {
                    $UpdateCount++    
                    foreach ($TSUG in $TargetSUG) {
                        Write-Progress -Activity "Creating Update Membership(s)" -Status "Processing Membership $UpdateCount of $($Updates.Count)..." -Id 2 -PercentComplete ($UpdateCount / $($Updates.Count) * 100) -CurrentOperation "Processing Membership(s) of $TSUG for Update: $($_.LocalizedDisplayName)"
                        Add-CMSoftwareUpdateToGroup -SoftwareUpdateId $_.CI_ID -SoftwareUpdateGroupName $TSUG
                        Write-Host "Target SUG: " -ForegroundColor Magenta -NoNewline
                        Write-Host "$TSUG" -ForegroundColor Cyan
                        Write-Host "Source SUG: " -ForegroundColor Magenta -NoNewline
                        Write-Host "$SUG" -ForegroundColor Cyan
                        Write-Host "Update:     " -ForegroundColor Magenta -NoNewline
                        Write-Host "$($_.LocalizedDisplayName)" -ForegroundColor Cyan
                        Write-Host
                        Write-Log -Message "Adding $($_.LocalizedDisplayName) to $TSUG from $SUG" -Severity 1 -Component "Transfer-SUGMemberships Loop In"
                    }
                } -End {
                    Write-Progress -Activity "Creating Update Membership(s)" -Completed
                }
            }
            catch {
                Write Warning "$_.Exception.Message"
                Write-Log -Message "$_.Exception.Message" -Severity 3 -Component "Transfer-SUGMemberships Loop"
            }
            Write-Host "------ End   $SUG -----" -ForegroundColor Gray  
            Write-Host # Spacing
        }
        Write-Progress -Activity "Transfering SUG(s) update membership(s)" -Completed
        Write-Progress -Activity "Creating Update Membership(s)" -Completed
    }
    catch {
        Write Warning "$_.Exception.Message"
        Write-Log -Message "$_.Exception.Message" -Severity 3 -Component "Transfer-SUGMemberships"
    }
    Write-Progress -Activity "Transfering SUG(s) update membership(s)" -Completed
    Write-Progress -Activity "Creating Update Membership(s)" -Completed
}
#########################################

# 3) Function Three Remove-UpdatesFromSUG
#########################################
Function Remove-UpdatesFromSUG {
    PARAM(
        [switch]$RemoveAllUpdates,
        [string[]]$SourceSUG
    )
    if ($RemoveAllUpdates -and $SourceSUG) {
        $UpdateTotal = Get-SUGUpdates -SourceSUG $SourceSUG
        $UpdateTotal | ForEach-Object -Begin {
            $UpdateTotalCount = 0
        } -Process {
            try {
            $UpdateTotalCount++
                Write-Host # Spacing
                Write-Host "----- Start $($_.LocalizedDisplayName) -----" -ForegroundColor Gray
                Write-Host # Spcaing
                foreach ($SUG in $SourceSUG) {
                    Write-Progress -Activity "Removing Membership: $($_.LocalizedDisplayName)" -Status "Removing $UpdateTotalCount of $($UpdateTotal.Count)..." -CurrentOperation "Edit Membership of $($_.LocalizedDisplayName) on SUG: $SUG " -PercentComplete ($UpdateTotalCount / $($UpdateTotal.Count) * 100)
                    Remove-CMSoftwareUpdateFromGroup -SoftwareUpdateId $_.CI_ID -SoftwareUpdateGroupName $SUG -Force -ErrorAction SilentlyContinue
                    Write-Host "Removing " -NoNewline -ForegroundColor Magenta
                    Write-Host "$($_.LocalizedDisplayName)" -ForegroundColor Cyan -NoNewline
                    Write-Host " from SUG: " -ForegroundColor Magenta -NoNewline
                    Write-Host "$SUG" -ForegroundColor Cyan
                    Write-Log -Message "Removing $($_.LocalizedDisplayName) from $SUG" -Severity 1 -Component "Remove-UpdatesFromSUG"
                }
            }
            catch {
                Write-Log -Message "Removing $($_.LocalizedDisplayName) from $SUG" -Severity 2 -Component "Remove-UpdatesFromSUG (error)"
                Write-Log -Message "$_.Exception.Message" -Severity 3 -Component "Remove-UpdatesFromSUG"
            }
        } -End {
            Write-Progress -Activity "Removing Membership: $($_.LocalizedDisplayName)" -Completed
        }
    }
    else {
        $SourceSUG = Get-SUGList -Title "Source SUG(s) to remove updates from"
        $UpdateTotal = Get-SUGUpdates -SourceSUG $SourceSUG
        $UpdateTargets = $updateTotal | Select-Object -Property LocalizedDisplayName, LocalizedDescription, CI_ID | Out-GridView -PassThru -Title "Select Updates to Remove"
        $UpdateTargets | ForEach-Object -Begin {
            $UpdateTotalCount = 0
        } -Process {
            try {
                $UpdateTotalCount++
                Write-Host # Spacing
                Write-Host "----- Start $($_.LocalizedDisplayName) -----" -ForegroundColor Gray
                Write-Host # Spcaing
                foreach ($SUG in $SourceSUG) {
                    Write-Progress -Activity "Removing Membership: $($_.LocalizedDisplayName)" -Status "Removing $UpdateTotalCount of $($UpdateTotal.Count)..." -CurrentOperation "Edit Membership of $($_.LocalizedDisplayName) on SUG: $SUG " -PercentComplete ($UpdateTotalCount / $($UpdateTotal.Count) * 100)
                    Remove-CMSoftwareUpdateFromGroup -SoftwareUpdateId $_.CI_ID -SoftwareUpdateGroupName $SUG -Force -ErrorAction SilentlyContinue
                    Write-Host "Removing " -NoNewline -ForegroundColor Magenta
                    Write-Host "$($_.LocalizedDisplayName)" -ForegroundColor Cyan -NoNewline
                    Write-Host " from SUG: " -ForegroundColor Magenta -NoNewline
                    Write-Host "$SUG" -ForegroundColor Cyan
                    Write-Log -Message "Removing $($_.LocalizedDisplayName) from $SUG" -Severity 1 -Component "Remove-UpdatesFromSUG"
                }
                Write-Host # Spacing
                Write-Host "----- End   $($_.LocalizedDisplayName) -----" -ForegroundColor Gray
                Write-Host # Spacing
                   
            }
            catch {
                Write-Log -Message "Removing $($_.LocalizedDisplayName) from $SUG" -Severity 2 -Component "Remove-UpdatesFromSUG (error)"
                Write-Log -Message "$_.Exception.Message" -Severity 3 -Component "Remove-UpdatesFromSUG"
            }
        } -End {
            Write-Progress -Activity "Removing Membership: $($_.LocalizedDisplayName)" -Completed
        }

    }
    Write-Progress -Activity "Removing Membership: $($_.LocalizedDisplayName)" -Completed
}
#########################################

# 4) Function Four Delete-SUG
#############################
Function Delete-SUG {
    PARAM(
        [switch]$DeleteSUG,
        [string[]]$SourceSUG
    )
    if ($DeleteSUG -and $SourceSUG) {
        $SourceSUG | ForEach-Object -Begin {
        } -Process {
            Write-Progress -Activity "Removing $_"
            Remove-CMSoftwareUpdateGroup -Name $_ -Force
            Write-Log -Message "Removed $_" -Severity 1 -Component "Delete SUG"
        } -End {
            Write-Progress -Activity "Removing $_" -Completed
        }
    }
    else {
        $SourceSUG = Get-SUGList -Title "SUG(s) to delete"
        $SourceSUG | ForEach-Object -Begin {
        } -Process {
            Write-Progress -Activity "Removing $_"
            Remove-CMSoftwareUpdateGroup -Name $_ -Force
            Write-Log -Message "Removed $_" -Severity 1 -Component "Delete SUG"
        } -End {
            Write-Progress -Activity "Removing $_" -Completed
        }
    }
}
#############################

# Q) Function Q Exit
####################
Function Exit-Script {
    # Exit
    Write-Host "Exiting..." -ForegroundColor Green
    Write-Log -Message "Exiting..." -Severity 1 -Component "EXIT"
    Set-Location $PSScriptRoot
    return
}

# Get Sug List Function
#######################
Function Get-SUGList {
    PARAM(
        [String]$Title
    )
    Write-Host "Retreiving all SUGs from $SiteCode ..." -ForegroundColor Yellow
    $SUGList = Get-CMSoftwareUpdateGroup | Select-Object DateCreated,LocalizedDisplayName,NumberOfUpdates,LocalizedDescription | Sort-Object DateCreated | Out-GridView -Title "Select $Title to continue..." -PassThru
    Write-Log -Message "Displayed SUG(s) to $env:USERNAME and they chose $($SUGList.LocalizedDisplayname)" -Severity 1 -Component "Get SUG List"
    return $SUGList.LocalizedDisplayname
}
#######################

# Get Updates from SUG
######################
Function Get-SUGUpdates ($SourceSUG) {
   
    $SourceSUG | ForEach-Object -Begin {
        $UpdateTotal = $null  
    } -Process {
        Write-Host "Gathering Updates from $_ ..." -ForegroundColor Yellow
        Write-Log -Message "Gathering Updates from $_" -Severity 1 -Component "Get SUG Updates"
        $Updates = Get-CMSoftwareUpdate -UpdateGroupName $_ -Fast
        Write-Host "Updates collected" -ForegroundColor Green
        Write-Log -Message "Updates collected" -Severity 1 -Component "Get SUG Updates"
        $UpdateTotal += $Updates
    } -End {
        Write-Host # Spacing
    }
    $UpdateTotal = $UpdateTotal | Select -Unique # Multiple objects passed can cause duplicate updates in var...
    return $UpdateTotal
}
######################


####################
# Param Directives #
####################

# CreateSUG Param Directive
###########################
if ($CreateSUG){
    Try {
        Create-SUG -NewSUGName $CreateSUG | Out-Null
        Write-Host "Created $CreateSUG" -ForegroundColor Green
    }
    Catch {
        Write-Log -Message "$_.Exception.Message" -Severity 3 -Component "CreateSUG Param"
    }
}
###########################

# Transfer SUG Membership Param Directive
#########################################
if ($SourceSUG -and $TargetSUG) {
    try {
        Transfer-SUGMemberships -TargetSUG $TargetSUG -SourceSUG $SourceSUG
    }
    catch {
        Write-Log -Message "$_.Exception.Message" -Severity 3 -Component "Transfer SUG Param"
    }
}
#########################################

# Remove Update from SUG Param Directive
########################################
if ($RemoveAllUpdates) {
    try {
        Remove-UpdatesFromSUG -RemoveAllUpdates -SourceSUG $RemoveAllUpdates
        Write-Log -Message "Remove Updates on User choice of: $RemoveAllUpdates" -Severity 1 -Component "Remove Update Param"
    }
    catch {
        Write-Log -Message "$_.Exception.Message" -Severity 3 -Component "Remove Update Param"
    }
}
########################################

# Delete SUG Directive
######################
if ($DeleteSUG) {
    Delete-SUG -DeleteSUG -SourceSUG $DeleteSUG
    Write-Log -Message "Delete SUG $DeleteSUG" -Severity 1 -Component "DeleteSUG PARAM"
}
######################

# Menu Param Directive
######################
if ($Menu) {
    # Calls Function based on selection
    do {
        Write-Log -Message "Loading User Menu" -Severity 1 -Component "MENU"
        Show-Menu
        $selection = (Read-Host "   Please make a selection").ToUpper()
        Write-Log -Message "$env:USERNAME Selected $selection" -Severity 1 -Component "MENU"
        switch ($selection) {
            '1' {Create-SUG}              # Create-SUG               1.)  Create a new SUG
            '2' {Transfer-SUGMemberships} # Transfer-SUGMemberships  2.)  Transfer Update membership between source SUGs and target SUGs
            '3' {Remove-UpdatesFromSUG}   # Remove-UpdatesFromSUG    3.)  Remoes updates from SUG using param directives or UI
            '4' {Delete-SUG}              # Delete-SUG               4.)  Delete SUG
            'Q' {Exit-Script
                 return}                  # Quit                     Q.)  Exit
        }
    pause
    }
    until ($input -eq 'Q')
}
######################
