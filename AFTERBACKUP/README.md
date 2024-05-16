# Additional Backup Steps for ConfigMgr Backup Process

## Introduction

This guide provides instructions for adding extra backup steps after the `SMS_SITE_BACKUP` process in Microsoft System Center Configuration Manager (ConfigMgr) by placing the `AFTERBACKUP.BAT` file in the specified directory.

## Instructions

1. **Download the `AFTERBACKUP.BAT` File:**
   - Obtain the `AFTERBACKUP.BAT` batch file that contains the additional backup steps you wish to run after the `sms_site_backup` process.

2. **Navigate to ConfigMgr Installation Location:**
   - Open File Explorer and navigate to your ConfigMgr installation location. Typically, this is:
     ```
     <ConfigManInstallLocation>\inboxes\smsbkup.box
     ```
     Replace `<ConfigManInstallLocation>` with the actual installation path of your ConfigMgr environment.

3. **Place `AFTERBACKUP.BAT` File:**
   - Move the `AFTERBACKUP.BAT` file to the `smsbkup.box` directory located in the ConfigMgr installation path.

4. **Verify Placement:**
   - Ensure that the `AFTERBACKUP.BAT` file is now located in the `smsbkup.box` directory.

5. **Run ConfigMgr Backup Process:**
   - Proceed with running the ConfigMgr backup process (`SMS_SITE_BACKUP`).
     - This process will automatically trigger the additional backup steps defined in the `AFTERBACKUP.BAT` file after completing the standard backup operations.

## Important Notes

- **Permissions:**
  - Ensure that the account running the ConfigMgr backup process has sufficient permissions to execute the `AFTERBACKUP.BAT` file and access any required resources.
  
- **Customization:**
  - Customize the `AFTERBACKUP.BAT` file according to your specific backup requirements and environment configurations. The provided `AFTERBACKUP.BAT` file is simply an example to kick off ideas.

- **Backup Integrity:**
  - Verify the integrity and functionality of the additional backup steps by testing the process in a non-production environment before implementing it in a production setting.

- **Backup Schedule:**
  - Ensure your `SMS_SITE_BACKUP` service is scheduled to run. For more information see: https://learn.microsoft.com/en-us/mem/configmgr/core/servers/manage/backup-and-recovery
