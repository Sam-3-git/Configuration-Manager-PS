###############################################################################
# # Date:   11/22/2023                                                      # #
# # Goal:   To obtain source files for use in air-gapped                    # #
# #         ConfigMan enviorments                                           # #
# # Version: 3.0                                                            # #
###############################################################################

<#
    .SYNOPSIS
        Script to download Windows Update files as needed for air-gapped ConfigMan sites.
   
    .DESCRIPTION
        Script used when trying to obtain source file. This script will check the meta data present in ConfigMan to determine download locations. Will not work with Expired or Superseded updates. Not tested with 3rd Party Update Publishers.

    .PARAMETER Articles
        Specify KB to search for in ConfigMan. Article IDs or Article Titles can be passed. Do not include "KB".

    .PARAMETER SiteCode
        ConfigMan Site Code

    .PARAMETER ProviderMachineName
        ConfigMan Site Server FQDN

    .PARAMETER GenerateScript
        Whether to Generate a download script to use from an internet connected system

    .EXAMPLE
        # To Download Files for one KB
        Get-UpdateSourceFiles.ps1 -Articles "5031539" -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain"
   
    .EXAMPLE
        # To Download Files for multiple KB
        Get-UpdateSourceFiles.ps1 -Articles "5031539","4484104" -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain"

    .EXAMPLE
        # To generate a script to run on an internet connected system
        Get-UpdateSourceFiles.ps1 -Articles "5031539" -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -GenerateScript
   
    .EXAMPLE
        # To download based off Article Name
        Get-UpdateSourceFiles.ps1 -Articles "Microsoft Edge-Beta Channel Version 120 Update for ARM64 based Editions (Build 120.0.2210.22)" -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain"

    .EXAMPLE
        # To download based off Wildcard. NOTE: Argument will be processed as 1 Article
        Get-UpdateSourceFiles.ps1 -Articles "*Windows 10*" -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain"

#>

# params
########
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [String[]]$Articles,
   
    [Parameter(Mandatory = $true)]
    [String]$SiteCode,

    [Parameter(Mandatory = $true)]
    [String]$ProviderMachineName,

    [Parameter()]
    [Switch]$GenerateScript

)
########

# Site configuration
#$SiteCode = "ABC" # Site code
#$ProviderMachineName = "SITESERVER" # SMS Provider machine name
$SiteCode = "$SiteCode" # Site code
$ProviderMachineName = "$ProviderMachineName" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

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

# Sets up Tree and logging
##########################
if (-not (Test-Path -Path "$PSScriptRoot\GetUpdateSourceFiles"))
{
    New-Item -Path $PSScriptRoot -Name 'GetUpdateSourceFiles' -ItemType Directory -Force
}
if (-not (Test-Path -Path "$PSScriptRoot\GetUpdateSourceFiles\SourcedFiles"))
{
    New-Item -Path $PSScriptRoot\GetUpdateSourceFiles -Name 'SourceFiles' -ItemType Directory -Force
}
# Creates Log File
$file = "$PSScriptRoot\GetUpdateSourceFiles\GetUpdateSourceFiles_{0:MMddyyyy_HHmm}.log" -f (Get-Date)

# Creates Transcript for logging
Start-Transcript -Path $file -IncludeInvocationHeader
##########################

# User Output Notification
##########################
Cls
Write-Host
Write-Host "SITE:   $SiteCode" -ForegroundColor DarkGray
Write-Host "SERVER: $ProviderMachineName" -ForegroundColor DarkGray
Write-Host "USER:   $env:USERNAME" -ForegroundColor DarkGray
Write-Host "LOG:    $file" -ForegroundColor DarkGray
Write-Host
##########################

########
# Vars #
########

$OutFilePath = "$PSScriptRoot\GetUpdateSourceFiles\SourceFiles"
$Count = 0
$ArticleIDCount = 0
$FoundArticles = 0
$ScriptBody = ""
$host.privatedata.ProgressForegroundColor = "Cyan"
$host.privatedata.ProgressBackgroundColor = "Black"
######
 
if ($GenerateScript) {
   
    # Generate Script for use on internet connected system.
    Write-Host "" # Spacing
    $script = "$PSScriptRoot\GetUpdateSourceFiles\Download-SourceFiles_{0:MMddyyyy_HHmm}.ps1" -f (Get-Date)
    Write-Host "Creating $script" -ForegroundColor Yellow
    New-Item -Path $script -ItemType File -Force
    #######################################################

    # Script Body to add to ps1
    ###########################
    $ScriptBody = @"
###############################################################################
# # Date: 11/22/2023                                                        # #
# # Goal: To obtain source files for use in air-gapped ConfigMan enviorments# #
# # Version: 3.0                                                            # #
###############################################################################

<#
    .SYNOPSIS
        Script to download Windows Update files as needed for air-gapped ConfigMan sites.
   
    .DESCRIPTION
        Script generated by Get-UpdateSourceFiles.ps1 to download files from an internet connected system. Downloaded files can then be read by air-gapped Site when targeted for downloades. Not tested with 3rd Party Update Publishers.

#>

# Sets up Tree and logging
##########################
if (-not (Test-Path -Path "`$PSScriptRoot\GetUpdateSourceFiles"))
{
    New-Item -Path `$PSScriptRoot -Name 'GetUpdateSourceFiles' -ItemType Directory -Force
}
if (-not (Test-Path -Path "`$PSScriptRoot\GetUpdateSourceFiles\SourcedFiles"))
{
    New-Item -Path `$PSScriptRoot\GetUpdateSourceFiles -Name 'SourceFiles' -ItemType Directory -Force
}
`$file = "`$PSScriptRoot\GetUpdateSourceFiles\Download-SourceFiles_{0:MMddyyyy_HHmm}.log" -f (Get-Date)
`$OutFilePath = "`$PSScriptRoot\GetUpdateSourceFiles\SourceFiles"
Start-Transcript -Path `$file
##########################

# User Output
#############
cls
Write-Host ""
Write-Host "Creating File Structure and Logging" -ForegroundColor Yellow
Write-Host ""
#############

# Vars
######
`$OutFilePath = "`$PSScriptRoot\GetUpdateSourceFiles\SourceFiles"
`$ArticleIDCount = 0
`$host.privatedata.ProgressForegroundColor = "Cyan"
`$host.privatedata.ProgressBackgroundColor = "Black"
######

"@
    Add-Content -Path $script -Value $ScriptBody
    ###########################

    $linkNumber = 0 # Used for passing varibles into generated script.
   
    # Process Passed Articles
    #########################
    foreach ($KB in $Articles){
        # Progress bar settings
        #######################
        $Count++
        Write-Progress -Activity "Writing Script for $KB..." -PercentComplete ($Count / $Articles.count * 100) -CurrentOperation "Processing $Count / $($Articles.count)..."
        #######################

        # Get Download links from $SiteCode
        ###################################
        try {
            $ArticleIDCount++
            $DownloadLinks = Get-CMSoftwareUpdate -ArticleId $KB -Fast | Where-Object {($_.IsSuperseded -ne $true) -and ($_.IsExpired -ne $true)} | Get-CMSoftwareUpdateContentInfo | Select-Object -ExpandProperty SourceURL
            if ($DownloadLinks -eq $null) { # if null, try on Title Name; Example edge does not have article ID and Title must be passed.
                $DownloadLinks = Get-CMSoftwareUpdate -Name $KB -Fast | Where-Object {($_.IsSuperseded -ne $true) -and ($_.IsExpired -ne $true)} | Get-CMSoftwareUpdateContentInfo | Select-Object -ExpandProperty SourceURL
                }
            if ($DownloadLinks -eq $null) { # output to user that $KB was not found.
                Write-Host "Article $KB not found in $SiteCode. Ensure Meta data for $KB has been imported into Data Base." -ForegroundColor Red
                Write-Host "https://learn.microsoft.com/en-us/mem/configmgr/sum/get-started/synchronize-software-updates-disconnected" -ForegroundColor Cyan
            }    
        }
        catch { # output to user that $KB was not found.
            Write-Warning "$_.Exception.Message"
            Write-Host "Article KB $KB not found in $SiteCode. Ensure Meta data for KB $KB has been imported into Data Base." -ForegroundColor Red
            Write-Host "https://learn.microsoft.com/en-us/mem/configmgr/sum/get-started/synchronize-software-updates-disconnected" -ForegroundColor Cyan
            $DownloadLinks = $null
        }
        ###################################

        # Write Download links and logic to generated script.
        #####################################################
        if ($DownloadLinks -ne $null) {

            # User Feedback
            ###############
            Write-Host "Parsing metadata on KB " -ForegroundColor Yellow -NoNewline  
            Write-Host "$KB" -ForegroundColor Green
            ###############

            $InnerCount = 0 # inner count for progress bar
            foreach ($link in $DownloadLinks) {
                $linkNumber++
                $InnerCount ++
                Write-Progress -Activity "Writing Script for $KB..." -Status "Finding KB Download Link(s) for $KB" -Id 1 -PercentComplete ($InnerCount / $DownloadLinks.count * 100) -CurrentOperation "Generating Link(s) $InnerCount / $($DownloadLinks.count) "
               
                # User Feedback
                ###############
                Write-Host "Found link for KB " -ForegroundColor Yellow -NoNewline
                Write-Host "$KB " -NoNewline -ForegroundColor Green
                Write-Host "at " -NoNewline -ForegroundColor Yellow
                Write-Host "$link" -ForegroundColor Cyan
                ###############

                # Add download output and variables to script
                #############################################
                Add-Content -Path $script -Value "# Download link info and commands"
                Add-Content -Path $script -Value "#################################"
                Add-Content -Path $script -Value "Write-Host 'Starting Download' -ForegroundColor Yellow"
                Add-Content -Value "`$$linkNumber = '$link'" -Path $script
                Add-Content -Path $script -Value "Write-Host `$$linkNumber -ForegroundColor Cyan"
                Add-Content -Path $script -Value "Write-Host ''"
                try {
                    $Value = "Start-BitsTransfer -Source $link -Destination `$OutFilePath" # Passed command for downloads
                    Add-Content -Path $script -Value $Value
                    Add-Content -Path $script -Value "Write-Host 'BITS Transfer Complete' -ForegroundColor Green"
                    Add-Content -Path $script -Value "Write-Host ''"
                    Write-Host "Download command published to script." -ForegroundColor Green
                }
                catch {
                    Write-Warning "$_.Exception.Message"
                    Write-Host "Download Failed at: " -ForegroundColor Red -NoNewline
                    Write-Host "$link" -ForegroundColor Cyan
                }
                Add-Content -Path $script -Value "#################################"
                Add-Content -Path $script -Value "" # Spacing
                #############################################
                 
            Write-Host "" # Spacing  
            }
        }
    }
    #########################

    # Stop Progress Bar
    ###################
    Write-Progress -Activity "Writing Script for $KB..." -Completed
    Write-Progress -Activity "Writing Script for $KB..." -Id 1 -Completed
    Write-Host "Script Writing complete." -ForegroundColor Green
    ###################

    # Publish end of script to generated script
    ###########################################
    $ScriptEnd = @"
# Article count processed in Get-updateSourceFile
#################################################
`$ArticleIDCount = $ArticleIDCount
#################################################

# Checks for files in sourced folder and validate signature for review
######################################################################
`$SourceFiles = Get-ChildItem -Path "`$PSScriptRoot\GetUpdateSourceFiles\SourceFiles"
`$SourceFiles | ForEach-Object -Begin {
        `$NotValidFile = 0 # count of non valid files
        `$CheckCount = 0 # count for progress bar
    } -Process {
        # Progress bar settings
        #######################
        `$CheckCount++
        `$Completed = (`$CheckCount/`$SourceFiles.count) * 100 # math for progress bar
        Write-Progress -Activity "Checking Signatures..." -Status "Checking `$(`$_.Name)" -PercentComplete `$Completed
        #######################

        # Get all sfile Sigs
        ####################
        `$authsig = Get-AuthenticodeSignature -FilePath `$_.FullName | Out-String
        ####################
   
        # Gets a file authsig and checks if it is valid.
        ################################################
        if (`$authsig -notmatch "Valid") {
            `$NotValidFile++
            Write-Warning "`$(`$_.FullName) could not be validated. Please review."
            Get-AuthenticodeSignature -FilePath `$_.FullName | Format-List
        }
        ################################################

    } -End {
        Write-Progress -Activity "Checking Signatures..." -Completed # close progress bar
        Write-Host "" # Spacing
    }
    ######################################################################

# End of script overview for user
#################################
Write-Output ""
Write-Output "----- Overview -----"
Write-Output "Log:                 `$file"
Write-Output "KB(s) Processed:     `$ArticleIDCount"
Write-Output "Source File(s):      `$PSScriptRoot\GetUpdateSourceFiles\SourceFiles"
Write-Output "File Count:          `$(`$SourceFiles.count)"
Write-Output "Non-Valid Signature: `$NotValidFile"
Write-Host ""
Write-Host "Exiting..." -ForegroundColor Green
Stop-Transcript
Set-Location `$PSScriptRoot
#################################
return
"@
    Add-Content -Path $script -Value $ScriptEnd
    ###########################################
}
else {

    # itterate passed param $articles to find then download source files.
    #####################################################################
    foreach ($KB in $Articles){
       
        # Progress bar
        ##############
        $Count++
        Write-Progress -Activity "Processing KB $KB..." -PercentComplete ($Count / $Articles.count * 100) -CurrentOperation "Processing $Count / $($Articles.count)..."
        ##############

        # Get Download links from $SiteCode try /catch
        ##############################################
        try {
            $ArticleIDCount++
            $DownloadLinks = Get-CMSoftwareUpdate -ArticleId $KB -Fast | Where-Object {($_.IsSuperseded -ne $true) -and ($_.IsExpired -ne $true)} | Get-CMSoftwareUpdateContentInfo | Select-Object -ExpandProperty SourceURL
           
            # if null, try on Title Name
            ############################
            if ($DownloadLinks -eq $null) {
                $DownloadLinks = Get-CMSoftwareUpdate -Name $KB -Fast | Where-Object {($_.IsSuperseded -ne $true) -and ($_.IsExpired -ne $true)} | Get-CMSoftwareUpdateContentInfo | Select-Object -ExpandProperty SourceURL
                }
            ############################

            # if still null write error
            ###########################
            if ($DownloadLinks -eq $null) {
                Write-Host "Article $KB not found in $SiteCode. Ensure Meta data for $KB has been imported into Data Base." -ForegroundColor Red
                Write-Host "https://learn.microsoft.com/en-us/mem/configmgr/sum/get-started/synchronize-software-updates-disconnected" -ForegroundColor Cyan
            }  
            ###########################
               
        }
        catch {
            Write-Warning "$_.Exception.Message"
            Write-Host "Article KB $KB not found in $SiteCode. Ensure Meta data for KB $KB has been imported into Data Base." -ForegroundColor Red
            Write-Host "https://learn.microsoft.com/en-us/mem/configmgr/sum/get-started/synchronize-software-updates-disconnected" -ForegroundColor Cyan
            $DownloadLinks = $null
        }
        ##############################################

        if ($DownloadLinks -ne $null) {

            # User Feedback
            ###############
            Write-Host "Parsing metadata on KB " -ForegroundColor Yellow -NoNewline  
            Write-Host "$KB" -ForegroundColor Cyan
            ###############

            $InnerCount = 0 # Count for inner prog bar

            # itterate $Downloadlink
            ########################
            foreach ($link in $DownloadLinks) {

                # Inner Prog Bar
                ################
                $InnerCount ++
                Write-Progress -Activity "Downloading KB $KB..." -Status "Downloading KB $KB from $link..." -Id 1 -PercentComplete ($InnerCount / $DownloadLinks.count * 100) -CurrentOperation "Downloading $InnerCount / $($DownloadLinks.count) source files from internet for KB $KB"
                ################

                # User Feedback
                ###############
                Write-Host "Found link for KB " -ForegroundColor Yellow -NoNewline
                Write-Host "$KB " -NoNewline -ForegroundColor Green
                Write-Host "at " -NoNewline -ForegroundColor Yellow
                Write-Host "$link" -ForegroundColor Cyan
                ###############

                # BITS try / catch
                ##################
                try {
                    Start-BitsTransfer -Source $link -Destination $OutFilePath
                    Write-Host "BITS Transfer Complete" -ForegroundColor Green
                }
                catch {
                    Write-Warning "$_.Exception.Message"
                    Write-Host "Download Failed at: " -ForegroundColor Red -NoNewline
                    Write-Host "$link" -ForegroundColor Cyan
                }
                ##################

                Write-Host "" # Spacing  
            }
            ########################

        }
    }
    #####################################################################

    # End Progress Bar
    ##################
    Write-Progress -Activity "Downloading KB $KB..." -Completed
    Write-Progress -Activity "Downloading KB $KB..." -Id 1 -Completed
    ##################

    # Checks for files in sourced folder and validate signature for review
    ######################################################################
    $SourceFiles = Get-ChildItem -Path "$PSScriptRoot\GetUpdateSourceFiles\SourceFiles"
    $SourceFiles | ForEach-Object -Begin {
        $NotValidFile = 0 # count of non valid files
        $CheckCount = 0 # count for progress bar
    } -Process {
        # Progress bar settings
        #######################
        $CheckCount++
        $Completed = ($CheckCount/$SourceFiles.count) * 100 # math for progress bar
        Write-Progress -Activity "Checking Signatures..." -Status "Checking $($_.Name)" -PercentComplete $Completed
        #######################

        # Get all sfile Sigs
        ####################
        $authsig = Get-AuthenticodeSignature -FilePath $_.FullName | Out-String
        ####################
   
        # Gets a file authsig and checks if it is valid.
        ################################################
        if ($authsig -notmatch "Valid") {
            $NotValidFile++
            Write-Warning "$($_.FullName) could not be validated. Please review."
            Get-AuthenticodeSignature -FilePath $_.FullName | Format-List
        }
        ################################################

    } -End {
        Write-Progress -Activity "Checking Signatures..." -Completed # close progress bar
        Write-Host "" # Spacing
    }
    ######################################################################
}

# End of script overview for user
#################################
Write-Output ""
Write-Output "----- Overview -----"
Write-Output "Server Name:         $ProviderMachineName"
Write-Output "Site Code:           $SiteCode"
Write-Output "Log:                 $file"
Write-Output "KB(s) Processed:     $ArticleIDCount"
if (!$GenerateScript) { # Check source files if not generating
    Write-Output "Source File(s):      $PSScriptRoot\GetUpdateSourceFiles\SourceFiles"
    Write-Output "File Count:          $($SourceFiles.count)"
    Write-Output "Non-Valid Signature: $NotValidFile"
}
#################################

# Exit.
#######
Write-Host ""
Write-Host "Exiting..." -ForegroundColor Green
Stop-Transcript
Set-Location $PSScriptRoot
return
#######
