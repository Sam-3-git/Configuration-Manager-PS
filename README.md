<h3 align="center">Configuration Manager Repo</h3>

<p align="center">
  Hello! 👋 Welcome to my repo of Configuration Manger tools. Enjoy your stay!
</p>

## Table of Contents

- [SUG Tool Box](#sug-tool-box)
- [Get Update Source Files](#get-update-source-files)
- [Create CM Collection Environment](#create-cm-collection-environment)
- [Create Local Admin Group Inventory](#create-ccm_localadmingroupdetails-wmi-class)
- [Functions](#functions)
  - Sort-CMDrivers
  - Write-Log
  - ConvertTo-CMBoundryIPSubnet

# Scripts
---
## SUG Tool Box <a name="sug-tool-box"></a>
[SUG-Toolbox.ps1](https://github.com/Sam-3-git/Configuration-Manager-PS/blob/main/Scripts/SUG-Toolbox.ps1)

Script used to perform creation, modification, and removal of Software Update Groups. Contains a user-driven menu to allow a more user-friendly experience.

### Parameters

- **SiteCode**
  - ConfigMan Site Code
- **ProviderMachineName**
  - ConfigMan Site Server FQDN
- **Menu**
  - Whether to run in menu mode. Menu mode allows the user to make selections based on input versus parameter mode where desired configurations are passed. Menu can be called to start the SUG Toolbox menu with any other parameters defined.
- **CreateSUG**
  - Specify a SUG name to create an empty SUG. CreateSUG is also available in MENU mode. Only one SUG can be created at a time with this parameter.
- **TargetSUG**
  - Specify SUG name(s) to target update membership. Target SUG(s) will be populated with any updates found in the SourceSUG(s). TargetSUG will only work with SourceSUG also defined.
- **SourceSUG**
  - Specify SUG name(s) to get update membership from. The Source SUG(s) will have their update membership scanned. Any updates found will be populated into the Target SUG. SourceSUG will only work when TargetSUG is also defined.
- **RemoveAllUpdates**
  - Specify SUG name(s) to remove all update membership. The passed SUG(s) will have all current update membership removed.
- **DeleteSUG**
  - Specify SUG name(s) to delete. The passed SUG(s) will be removed.

The passed parameters are run in the following order: 
- `CreateSUG`
- `TargetSUG`
- `SourceSUG`
- `RemoveAllUpdates`
- `DeleteSUG`
- `Menu`

### Examples

```powershell
# To start script in MENU mode
SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -Menu

# To create a new empty SUG
SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -CreateSUG "Example SUG01"

# To create a new empty SUG then start MENU mode
SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -CreateSUG "Example SUG01" -Menu

# To create update membership on a Target SUG that is defined in a Source SUG
SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -TargetSUG "No Membership SUG01" -SourceSUG "Many Update Membership SUG01"

# To create update membership on a newly created Target SUG that is defined in multiple Source SUG(s)
SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -CreateSUG "New SUG01" -TargetSUG "New SUG01" -SourceSUG "Many Update Membership SUG01","Many Update Membership SUG02"

# To remove all updates from SUG(s)
SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -RemoveAllUpdates "Many Update Membership SUG01","Many Update Membership SUG02"

# To delete SUG(s)
SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -DeleteSUG "Old SUG01","Old SUG02"

# To do all operations
SUG-Toolbox.ps1 -SiteCode "ABC" -ProviderMachineName "HOSTNAME.domain" -CreateSUG "New SUG01" -TargetSUG "New SUG01" -SourceSUG "Old SUG01","Old SUG02" -RemoveAllUpdates "Old SUG01" -DeleteSUG "OldSUG02" -Menu
```



## Get Update Source Files <a name = "get-update-source-files"></a>
[Get-UpdateSourceFile](https://github.com/Sam-3-git/Configuration-Manager-PS/blob/main/Scripts/Get-UpdateSourceFile.ps1)

Script used to obtain software update source binaries. This script will query config man to pull microsoft download locations per target software update. There is the option to download to a source directory or create a download script which can be run on any internet connected system. Creates the following directory structure in the root of where script is run:
- `\GetUpdateSourceFiles` (contains log files and any generated scripts)
    - `\SourcedFiles` (contains sourced update binaries. point to this folder when downloading an update from within the config man console.)

Target updates must be present in Config Man. Not tested with 3rd Party Update Publishers. 

### Parameters

- **Articles**
  - Specify Article IDs to search for in ConfigMan. Article IDs or Article Titles can also be passed
- **SiteCode**
  - ConfigMan Site Code
- **ProviderMachineName**
  - ConfigMan Site Server FQDN
- **GenerateScript**
  - Switch to Generate a download script to use from an internet connected system

### Examples

```powershell
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
```

## Create CM Collection Enviorment <a name = "create-cm-collection-environment"></a>
[Create-CMCollectionEnviorment](https://github.com/Sam-3-git/Configuration-Manager-PS/tree/main/Scripts/Create-CMCollectionEnviorment)

This script is designed to create device collections and organize them into structured folders. It will create a collection, inject a query if needed, and move the collection to the appropriate folder. Collections are built based on criteria specified in the `Create-CMCollectionEnvironment.csv` file.

### Installation Guide

1. Download the necessary scripts and files:
   - [Create-CMCollectionEnviorment.csv](https://github.com/Sam-3-git/Configuration-Manager-PS/blob/main/Scripts/Create-CMCollectionEnviorment/Create-CMCollectionEnviorment.csv)
   - [Create-CMCollectionEnviorment.ps1](https://github.com/Sam-3-git/Configuration-Manager-PS/blob/main/Scripts/Create-CMCollectionEnviorment/Create-CMCollectionEnviorment.ps1)

3. Run the script with the appropriate parameters:
   - Ensure you have the necessary permissions (Full Administrator role in SCCM).
   - Navigate to the directory where you downloaded the files.
   
```powershell
.\CCM_LocalAdminGroupSetup.ps1 -SiteCode <YourSiteCode> -ProviderMachineName <YourProviderMachineName>
```

### Notes
- Ensure that `Create-CMCollectionEnviorment.csv` is in the same root directory as the script.
- If in a CAS environment, run this script at the CAS level.
- An update to membership collection may be required after creation.
- A reload to the console will be necessary for new device collection folders to be viewed.
- Additional Hardware Inventory classes are required in the default settings.
    - Installed Software - Asset Intelligence (SMS_InstalledSoftware) 
    - Software Licensing Product - Asset Intelligence (SoftwareLicensingProduct)
    - Client Diagnostics (CCM_ClientDiagnostics)

## Create CCM_LocalAdminGroupDetails WMI Class <a name = "create-ccm_localadmingroupdetails-wmi-class"></a>
[CCM_LocalAdminGroup](https://github.com/Sam-3-git/Configuration-Manager-PS/tree/main/Scripts/CCM_LocalAdminGroup)

This script is designed to create a new WMI class, `CCM_LocalAdminGroupDetails`. The `CCM_LocalAdminGroup.ps1` script is executed as a compliance item. The `CCM_LocalAdminGroupSetup.ps1` script imports both `CCM_LocalAdminGroupDetails.cab` and `CCM_LocalAdminGroup.mof` into the compliance baseline section and the default client setting's hardware inventory classes, respectively.

By default, the compliance baseline deploys to `All Desktop and Server Clients`. You can change the deployment to a desired collection by using the `-CMDeviceCollectionName` parameter when running `CCM_LocalAdminGroupSetup.ps1`.

This script inventories details of the local administrator group on the targeted collections. The following properties are inventoried:

- Account Name
- Domain
- Object Class (User or Group)
- Password Last Set Date
- Principal Source (Active Directory or Local)
- Account Enabled
- SID

The instance of the class can then be queried using the Resource Explorer. Collection queries can be created based on the `CCM_LocalAdminGroupDetails` properties using WQL.

### Installation Guide

1. Download the zip file containing the necessary scripts and files:
   - [CCM_LocalAdminGroup.zip](https://github.com/Sam-3-git/Configuration-Manager-PS/blob/main/Scripts/CCM_LocalAdminGroup/CCM_LocalAdminGroup.zip)

2. Extract the contents of the zip file to a desired location:

```powershell
Expand-Archive -Path .\CCM_LocalAdminGroup.zip -DestinationPath C:\desired\location
```
3. Run the script with the appropriate parameters:
   - Ensure you have the necessary permissions (Full Administrator role in SCCM).
   - Navigate to the directory where you extracted the files.
   
```powershell
.\CCM_LocalAdminGroupSetup.ps1 -SiteCode <YourSiteCode> -ProviderMachineName <YourProviderMachineName> -CMDeviceCollectionName <YourCMDeviceCollectionName>
```
### Notes
- Ensure that `CCM_LocalAdminGroup.mof` and `CCM_LocalAdminGroupDetails.cab` are in the same root directory as the script.
- If in a CAS environment, run this script at the CAS and not the primary site.

# Functions <a name = "functions"></a>
---
Various [Functions](https://github.com/Sam-3-git/Configuration-Manager-PS/tree/main/Functions) used for quick ConfigMan tasks.

[Sort-CMDrivers](https://github.com/Sam-3-git/Configuration-Manager-PS/blob/main/Functions/Sort-CMDrivers)

This PowerShell function organizes Configuration Manager (CM) drivers based on a specified criterion (`$SortBy`). It creates folders under the `Driver` parent folder using `$SortBy` as the folder name, then moves CM objects into these folders according to the sorting criteria. Finally, it prompts the user to reload the CM console to view the changes.
```powershell
    .EXAMPLE
        # Sort a single driver
        Get-CMDriver -Name "Intel(R) Precise Touch Device" -Fast | Sort-CMDrivers -SortBy "Touch Drivers"
   
    .EXAMPLE
        # Sort by user citeria
        Get-CMDriver -Fast | Where-Object {$_.DriverProvider -eq "Microsoft"} | Sort-CMDrivers -SortBy "Microsoft"

    .EXAMPLE
        # Sort all drivers by class
        Get-CMDriver -Fast | Select-Object -ExpandProperty DriverClass -Unique | ForEach-Object -Process {Get-CMDriver -Fast | Where-Object -Property DriverClass -EQ $_ | Sort-CMDrivers -SortBy $_}
```

[Write-Log](https://github.com/Sam-3-git/Configuration-Manager-PS/blob/main/Functions/Write-Log)

This PowerShell function is designed to write logs that are easily interperted by `CMTrace.exe`.
```powershell
    .EXAMPLE
    Write-Log -Message "Info: This is the start of the log" -Severity 1 -Component "BEGIN"

    .EXAMPLE
    Write-Log -Message "Warning: This is a warning in the middle of the log" -Severity 2 -Component "PROCESS"

    .EXAMPLE
    Write-Log -Message "Error: This is a terminiating error for some process... $SomeProcessPassedExitCode" -Severity 3 -Component "END"
```

[ConvertTo-CMBoundryIPSubnet](https://github.com/Sam-3-git/Configuration-Manager-PS/blob/main/Functions/ConvertTo-CMBoundryIPSubnet)

This PowerShell function creates site boundries based off Active Directory Sites and Services. Uses a combination of Site Name properties and subnet values to create boundries that are easily identified. Does not work with ipv6 subnets. Function is designed to take input from `Get-ADReplicationSubnet`.
```powershell
    .EXAMPLE
    Get-ADReplicationSubnet -Filter * | ConvertTo-CMBoundryIPSubnet
```
