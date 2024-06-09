## Installation Guide

1. Download the zip file containing the necessary scripts and files:
   - [CCM_LocalAdminGroup.zip](link-to-zip-file)

2. Extract the contents of the zip file to a desired location:

```powershell
Expand-Archive -Path .\CCM_LocalAdminGroup.zip -DestinationPath C:\desired\location
```
3. Run the script with the appropriate parameters:
   - 3a.  Ensure you have the necessary permissions (Full Administrator role in SCCM).
   - 3b.  Navigate to the directory where you extracted the files.
   
```powershell
.\CCM_LocalAdminGroupSetup.ps1 -SiteCode <YourSiteCode> -ProviderMachineName <YourProviderMachineName> -CMDeviceCollectionName <YourCMDeviceCollectionName>
```
## Notes
- Ensure that `CCM_LocalAdminGroup.mof` and `CCM_LocalAdminGroupDetails` are in the same root directory as the script.
- If in a CAS environment, run this script at the CAS and not the primary site.
