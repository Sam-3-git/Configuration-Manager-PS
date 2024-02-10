<h3 align="center">Configuration Manager PS Repo</h3>


<p align = "center">Hello! 👋 Welcome to my repo of Config Man Powershell Tools. Enjoy your stay!</p>


## Table of Contents

- [SUG Tool Box](#sug-tool-box-)
- [Get Update Source Files](#get-update-source-files-)

# SUG Tool Box <a name = "SUGToolBox"></a>
[Sug-Toolbox.ps1](https://github.com/Sam-3-git/Configuration-Manager-PS-Scripts/blob/main/Scripts/SUG-Toolbox.ps1) - Code

Script used to preform creation, modification, and removal of Software Update Groups. Contains a user driven menu to allow a more user friendly experience. 

Parameters

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

The passed parameters are run in the following order: 
- CreateSUG
- TargetSUG
- SourceSUG
- RemoveAllUpdates
- DeleteSUG
- Menu.  

Examples

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


# Get Update Source Files <a name = "#GetUpdateSourceFiles"></a>
[Get-UpdateSourceFile](https://github.com/Sam-3-git/Configuration-Manager-PS-Scripts/blob/main/Scripts/Get-UpdateSourceFile.ps1) - Code

Script used to obtain software update source binaries. This script will query config man to pull microsoft download locations per target software update. There is the option to download to a source directory or create a download script which can be run on any internet connected system. Creates the following directory structure in the root of where script is run:
- \GetUpdateSourceFiles (contains log files and any generated scripts)
    - \SourcedFiles (contains sourced update binaries. point to this folder when downloading an update from within the config man console.)

Target updates must be present in Config Man. Not tested with 3rd Party Update Publishers. 

Parameters

    .PARAMETER Articles
        Specify Article IDs to search for in ConfigMan. Article IDs or Article Titles can also be passed.

    .PARAMETER SiteCode
        ConfigMan Site Code

    .PARAMETER ProviderMachineName
        ConfigMan Site Server FQDN

    .PARAMETER GenerateScript
        Switch to Generate a download script to use from an internet connected system

Examples

    .EXAMPLE
        # To Download Files for one KB
        Get-UpdateSourceFiles.ps1  -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -Articles "5031539"
   
    .EXAMPLE
        # To Download Files for multiple KB
        Get-UpdateSourceFiles.ps1  -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -Articles "5031539","4484104"

    .EXAMPLE
        # To generate a script a download script to run later
        Get-UpdateSourceFiles.ps1  -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -Articles "5031539" -GenerateScript
   
    .EXAMPLE
        # To download based off Article Name
        Get-UpdateSourceFiles.ps1  -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -Articles "Microsoft Edge-Beta Channel Version 120 Update for ARM64 based Editions (Build 120.0.2210.22)"

    .EXAMPLE
        # To download based off Wildcard. NOTE: passed argument will be processed as 1 Article
        Get-UpdateSourceFiles.ps1  -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -Articles "*Windows 10*"

