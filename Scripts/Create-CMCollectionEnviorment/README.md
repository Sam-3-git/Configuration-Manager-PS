


# Create-CMCollectionEnvironment

Script used to create CM device collections for new or existing enviorments. Create-CMCollectionEnviorment.ps1 and Create-CMCollectionEnviorment.csv must be in the same directory when running Create-CMCollectionEnviorment.ps1. Simply add additional values to the csv if custom collections are wanted in addition to the exisiting Create-CMCollectionEnviorment.csv file. Some collections depend on additional hardware classes to be enabled in the Client Settings.

---

Additional Hardware Inventory classes that are required in the default settings.

 - Installed Software - Asset Intelligence (SMS_InstalledSoftware) 
 - Software Licensing Product - Asset Intelligence (SoftwareLicensingProduct)
 - Client Diagnostics (CCM_ClientDiagnostics) 
