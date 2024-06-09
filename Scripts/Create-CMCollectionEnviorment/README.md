## Installation Guide

1. Download the necessary scripts and files:
   - [Create-CMCollectionEnviorment.csv](link-to-zip-file)
   - [Create-CMCollectionEnviorment.ps1](link-to-zip-file)

3. Run the script with the appropriate parameters:
   - Ensure you have the necessary permissions (Full Administrator role in SCCM).
   - Navigate to the directory where you downloaded the files.
   
```powershell
.\CCM_LocalAdminGroupSetup.ps1 -SiteCode <YourSiteCode> -ProviderMachineName <YourProviderMachineName>
```
## Notes
- Ensure that `Create-CMCollectionEnviorment.csv` is in the same root directory as the script.
- If in a CAS environment, run this script at the CAS level.
- Additional Hardware Inventory classes are required in the default settings.
    - Installed Software - Asset Intelligence (SMS_InstalledSoftware) 
    - Software Licensing Product - Asset Intelligence (SoftwareLicensingProduct)
    - Client Diagnostics (CCM_ClientDiagnostics) 
