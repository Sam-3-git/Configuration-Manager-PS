<h3 align="center">Configuration Manager PS Scripts</h3>


<p align = "center">Hello! 👋 Welcome to my repo of Config Man Powershell Scripts. Enjoy your stay!</p>


## Table of Contents

- [SUG Tool Box](#SUG_ToolBox)


## SUG Tool Box <a name = "SUG_ToolBox"></a>
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

