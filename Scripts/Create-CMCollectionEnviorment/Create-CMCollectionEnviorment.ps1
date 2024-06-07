###############################################################################
# # Author: Sam                                                             # #
# # Script: Create-CMCollectionEnviorment                                   # #
# # Date:   01/16/2024                                                      # #
# # Goal:   To create initial collections in CM Enviorment                  # #
###############################################################################
<#
    .SYNOPSIS
        Script to setup CMDeviceCollections in a new enviorment

    .DESCRIPTION
        Script used to preform initial creation of Device Collections in ConfigMan enviorments.

    .PARAMETER SiteCode
        ConfigMan Site Code

    .PARAMETER ProviderMachineName
        ConfigMan Site Server FQDN

    .EXAMPLE
        Create-CMCollectionEnviorment.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain"
#>

 

# params
########

[CmdletBinding()]
PARAM (
    [Parameter(Mandatory = $true)]
    [String]$SiteCode,
    [Parameter(Mandatory = $true)]
    [String]$ProviderMachineName
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

# Exit Script
#############
Function Exit-Script {
    # Exit
    Write-Host "Exiting..." -ForegroundColor Green
    Set-Location $PSScriptRoot
    return
}

########
# Vars #
########

Cls
Write-Host "SITE:   $SiteCode" -ForegroundColor DarkGray
Write-Host "SERVER: $ProviderMachineName" -ForegroundColor DarkGray
Write-Host "USER:   $env:USERNAME" -ForegroundColor DarkGray
Write-Host
Write-Host

# Needed Hardware Classes
#########################
Write-Host "The following hardware classes must be enabled for some collections:" -ForegroundColor Yellow
Write-Host "Navigate to " -ForegroundColor Green -NoNewline
Write-Host "Administration > Client Settings > Default Client Settings > Properties" -ForegroundColor Cyan
Write-Host "Click Set Classes > Add " -ForegroundColor Green
Write-Host "Installed Software - Asset Intelligence (SMS_InstalledSoftware)" -ForegroundColor Cyan
Write-Host "Software Licensing Product - Asset Intelligence (SoftwareLicensingProduct)" -ForegroundColor Cyan
Write-Host "Client Diagnostics (CCM_ClientDiagnostics)" -ForegroundColor Cyan
Write-Host "Please make your changes now then come back to continue script" -ForegroundColor Green
pause
Write-Host
Write-Host

# CSV Data
##########
try {
    $CMDataSet = Import-Csv -Path $PSScriptRoot\Create-CMCollectionEnviorment.csv
} catch {
    Write-Error 'SEVERE: Unable to fetch $PSScriptRoot\Create-CMCollectionEnviorment.csv'
    Exit-Script
}

# Folders to create
###################
$Folders = $CMDataSet | Select-Object -ExpandProperty Folder -Unique
$FolderArray = New-Object System.Collections.ArrayList
foreach ($Folder in $Folders) {
    $FolderArray.Add($Folder) | Out-Null
}

###########
# Classes #
###########

# Collection Class
##################
class Collection {
    # Class properties
    [string] $Name
    [string] $Query  
    [string] $Comment 
    [string] $Limit
    [string] $Folder
    [string] $SiteCode

    # init
    Collection() {$this.Init(@{})}
    # hashtable constructor for building on class
    Collection([hashtable]$Properties) {$this.Init($Properties)}
    # standard constructor
    Collection([string]$Name,[string]$Query,[string]$Comment,[string] $Limit,[string] $Folder,[string]$SiteCode) {
        $this.Init(@{Name=$Name;Query=$Query;Comment=$Comment;Limit=$Limit;Folder=$Folder;SiteCode=$SiteCode})
    }
    # create property objects
    [void] Init([hashtable]$Properties) {
        foreach ($Property in $Properties.Keys) {
            $this.$Property = $Properties.$Property
        }
    }
    # methods

    # create()
    ##########
    [string] create() {
        [string]$return = $null
        try {
            New-CMDeviceCollection -Name $this.Name -LimitingCollectionName $this.Limit -Comment $this.Comment | Out-Null
            $return = "$($this.Name) has been created"
        } catch [System.ArgumentException] {
            $return = "Skipping $($this.Name); already exists"
        } catch {
            $return = $PSItem.Exception.Message
        }
        return $return
    }

    # inject()
    ##########
    [string] inject() {
        [string]$return = $null
        try {
            Add-CMDeviceCollectionQueryMembershipRule -CollectionName $this.Name -QueryExpression $this.Query -RuleName $this.Comment | Out-Null
            $return = "Query injected.."
        } catch {
            $return = $PSItem.Exception.Message
        }
        return $return
    }

    # move()
    ########
    [string] move() {
        [string]$return = $null
        try {
            Get-CMDeviceCollection -Name $this.Name | Move-CMObject -FolderPath "$($this.SiteCode)`:\DeviceCollection\$($this.Folder)"
            $return = "Object moved to \$($this.Folder).."
        } catch {
            $return = $PSItem.Exception.Message
        }
        return $return
    }

    # window()
    ##########
    [string] window() {
        [string]$return = $null
        [string]$pattern = $null
        [string]$day = $null
        [PSObject]$MWSchedule = $null
        try {
            $pattern = '\b(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b'
            if ($this.Name -match $pattern) {
                $day = $matches[0]
            }
            $MWSchedule = New-CMSchedule -DayOfWeek $day -DurationCount 6 -DurationInterval Hours -Start $this.Comment  # comment used to get necessary info "10/12/2013 00:00:00" > reflect in csv
            New-CMMaintenanceWindow -CollectionName $this.Name -Name $this.Name -Schedule $MWSchedule | Out-Null
            $return = "Created $($this.Folder) on $($this.Name).."
        } catch {
            $return = $PSItem.Exception.Message
        }
        return $return
    }
}

#############
# Functions #
#############

# Add-CMDeviceCollectionFolders
##################################
Function Add-CMDeviceCollectionFolders {
    <#
    .DESCRIPTION
        Function to create structure for desired CMDeviceCollection folders. Inteded use in Creat-CMCollectionEnviorment.ps1
    .PARAMETER CMDeviceCollectionFolderArrayList
        Parameter to pass an array of folder names to create directory structure
    .EXAMPLE
        # Create Folders
        Create-CMCollectionEnviorment -CMDeviceCollectionFolderArrayList $FoldersToCreate
    #>
    PARAM (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList]$CMDeviceCollectionFolderArrayList
    )
    $CMDeviceCollectionFolderArrayList.ForEach({
        if (Test-Path -Path "$SiteCode`:\DeviceCollection\$_") {
            Write-Verbose "INFO: $SiteCode`:\DeviceCollection\$_ exists"
            Write-Host "$SiteCode`:\DeviceCollection\$_ already exits" -ForegroundColor Green
        } else {
            Write-Verbose "Warning: $SiteCode`:\DeviceCollection\$_ does not exist"
            Write-Verbose "Creating..."
            try {
                New-CMFolder -Name $_ -ParentFolderPath DeviceCollection | Out-Null
                Write-Host "Created $SiteCode`:\DeviceCollection\$_" -ForegroundColor Green
            } catch {
                Write-Error "CRITICAL: Failed to create Folder $_"
                Exit-Script
            }
        }
    })
}



########
# Main #
########

# Create folder structure
#########################

# add direct memeber ship desired folders not present in query csv
Add-CMDeviceCollectionFolders -CMDeviceCollectionFolderArrayList $FolderArray

# Create Query Collections based on CSV Data
############################################
$CMDataSet | ForEach-Object -Begin {
    $NoQueryPattern = '\b(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b'
} -Process {
    $CollectionObject = [Collection]@{Name=$_.Name;Query=$_.Query;Comment=$_.Comment;Limit=$_.Limit;Folder=$_.Folder;SiteCode=$SiteCode}
    $return = $CollectionObject.create()
    Write-Host # Spacing
    $return
    switch ($return) {
        "Skipping $($CollectionObject.Name); already exists" {
            # DO NOTHING AS COLLECTION ALREADY EXISTS
        }
        {$_ -match $NoQueryPattern} { # no need to inject maintenance window collections. maint win collec will always have day of week in the name. 
            $CollectionObject.window()
            $CollectionObject.move()  
        }
        Default {
            $CollectionObject.inject()
            $CollectionObject.move()     
        }
    }
} -End {
    Write-Host 
    Write-Host "Completed all directives... Thank you for using Create-CMCollectionEnviorment" -ForegroundColor Green
}


# Exit
######
Exit-Script