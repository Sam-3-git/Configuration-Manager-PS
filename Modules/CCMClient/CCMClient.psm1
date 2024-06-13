Function Get-CCMLog {
    <#
        .SYNOPSIS
        Parses Configuration Manager Logs to provide an output similar to CMtrace, but in  powershell.
 
        .DESCRIPTION
        This Cmdlet is designed to parse the raw data of Configuration Manager Logs and provide a similar experience to CMTrace in the shell.
        REGEX is applied to the raw data found in the log. REGEX Matches are then split into groupings that represent the diffrent fields in CMTrace.
        The REGEX groupings are then assigned to various properties and assigned to an output object. New lines are removed from the message text.
        The cmdlet is designed to parse only Configuration Manger Logs or logs written in the same raw data style.
       
        .PARAMETER Path
        Path to Target Configuration Manager Logs. More than one log path can be passed at a time.
 
        .PARAMETER Filter
        Filters based on the type of message in the log; "Success","Info","Warning","Error".
        
        .PARAMETER ComputerName
        Specifies a computer name. Only One computer name at a time can be passed. Pipeline values are also allowed.
        Type the NetBIOS name, the IP address, or the fully qualified domain name of the computer. You can also pipe computer names to Get-CCMLog.
 
        .PARAMETER Credential
        Specifies a user account that has permission to perform this action.
 
        .EXAMPLE
        Get-CCMLog -LogPath "C:\Windows\CCM\Logs\PolicyAgent.log"
 
        .EXAMPLE
        Get-CCMLog -LogPath "C:\Windows\CCM\Logs\PolicyAgent.log","C:\Windows\CCM\Logs\ClientIDManagerStartup.log"
 
        .EXAMPLE
        Get-CCMLog -LogPath "C:\Windows\CCM\Logs\AppEnforce.log" -Filter Error
 
        .EXAMPLE
        Get-CCMLog -Path "C:\Windows\CCM\Logs\PolicyAgent.log" -ComputerName host.domain -Credential domain\admin01
 
        .INPUTS
        System.String
 
        .OUTPUTS
        System.Management.Automation.PSCustomObject 
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory = $true,ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,
 
        [Parameter()]
        [ValidateSet("Success","Info","Warning","Error")]
        [string]$Filter,
 
        [Parameter(ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [Alias('hostname','PSComputerName')]
        [string]$ComputerName="$ENV:COMPUTERNAME",
 
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.Credential()]$Credential
    )
    BEGIN {
        # want to check extension and ensure that .log is passed. may work on other files if emulating cmtrace logging. warn user.
        $Path | ForEach-Object -Process {
            $logext = [IO.Path]::GetExtension($Path)
            if ($logext -eq ".log") {
 
            } else {
                Write-Warning "WARNING: $logext is not valid .log extension"
            }
        }
        <################
        # REGEX Pattern #
        #################
        Group 2 = Message
        Group 5 = Time
        Group 7 = Date
        Group 9 = Component
        Group 11 = Type
        Group 13 = Thread
        '(?s)<!(\[LOG\[.*?)(.*?)(\]LOG\])(.*?time=")(\d\d\D\d\d\D\d\d\D\d\d\d)(.*?date=")(\d\d\D\d\d\D\d\d\d\d)(".component=")(.*?)(\".context="".type=")(\d)(".thread=")(.*?)(")(.*?)[^!]>'
        Groups       1        2     3         4                 5                  6              7                   8          9           10            11     12       13  14  15
        #################>
        $Pattern = '(?s)<!(\[LOG\[.*?)(.*?)(\]LOG\])(.*?time=")(\d\d\D\d\d\D\d\d\D\d\d\d)(.*?date=")(\d\d\D\d\d\D\d\d\d\d)(".component=")(.*?)(\".context="".type=")(\d)(".thread=")(.*?)(")(.*?)[^!]>'
        Write-Verbose "Regex Message pattern = $Pattern"
        }
    PROCESS {
        Write-Verbose "INFO: passed logs $Path"
        if ($ComputerName) {
            Write-Verbose "INFO: $ComputerName"
            $LogContent = Invoke-Command -ComputerName "$ComputerName" -Credential $Credential -ScriptBlock {Get-Content -Path $Using:Path -Raw}
        } else {      
            $LogContent = Get-Content -Path $Path -Raw
        }
        $RegexMatches = [regex]::Matches($LogContent, $Pattern)
        Write-Verbose "REGEXMATCH COUNT = $($RegexMatches.Count)"
        $RegexMatches | ForEach-Object {
            $DateTime = "$($_.Groups[7].Value) $($_.Groups[5].Value)"
            $DateTime = [datetime]::ParseExact($StringDate, 'MM-dd-yyyy HH:mm:ss.fff', $null)
            $Message = $_.Groups[2].Value
            $Message = $Message -replace '\r?\n', ' '
            $Type = $_.Groups[11].Value
            $Component = $_.Groups[9].Value
            $Thread = $_.Groups[13].Value
            # translate type to error value
            switch ($Type) {
                '1' {$Type = 'Info'}
                '0' {$Type = 'Success'}
                '2' {$Type = 'Warning'}
                '3' {$Type = 'Error'}
                default {$Type = 'Unknown'}
            }
            # Create output object for match item
            $OutputObject = New-Object -TypeName psobject -Property @{
                'Date\Time' = $DateTime
                'Message' = $Message
                'Type' = $Type
                'Component' = $Component
                'Thread' = $Thread
            }
            switch ($Filter) {
                'Info' {if ($Type -eq 'Info') {Write-Output $OutputObject}}
                'Success' {if ($Type -eq 'Success') {Write-Output $OutputObject}}
                'Warning' {if ($Type -eq 'Warning') {Write-Output $OutputObject}}
                'Error' {if ($Type -eq 'Error') {Write-Output $OutputObject}}
                default {Write-Output $OutputObject}
            }
        }          
    }
}
 
Function Invoke-CCMClientAction {
    <#
        .SYNOPSIS
        Invokes CCM Clients to run a desired action
 
        .DESCRIPTION
        This Cmdlet is designed to invoke WMI trigger actions on a local or remote system. This is similar to the Configuration Manager Applet found in Control Panel.
        Elevated permissions may be needed to access the namespace for the local or target system. This cmdlet creates a wrapper for
        Invoke-WMIMethod against the namespace root\ccm, class SMS_Client, method TriggerSchedule. The Action Parameter has a validated set
        for all CCM triggers that can be called. Please note that some triggers are no longer used.
 
       
        .PARAMETER Action
        Specefies the Action that will trigger on the system. Actions are mapped to schedule triggers.
 
        .PARAMETER ComputerName
        Specifies a computer name. More than one computer name is allowed to be passed. Pipeline values are also allowed.
        Type the NetBIOS name, the IP address, or the fully qualified domain name of the computer. You can also pipe computer names to Invoke-CCMClientAction.
 
        .PARAMETER Credential
        Specifies a user account that has permission to perform this action.
 
        .PARAMETER List
        Switch used to output a hashtable of all known methods.
 
        .EXAMPLE
        Invoke-CCMClientAction -Action 'Machine Policy Evaluation','Scan by Update Source'
 
        .EXAMPLE
        Invoke-CCMClientAction -Action 'Machine Policy Evaluation' -ComputerName hostname.domain -Credential domain\admin01
 
        .Example
        Invoke-CCMClientAction -List
 
        .INPUTS
        System.String

        .OUTPUTS
        System.Management.Automation.PSCustomObject
        System.Collections.Hashtable 
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter()]
        [ValidateSet('Hardware Inventory','Software Inventory','Application Evaluation','Data Discovery Record','File Collection',
                     'IDMIF Collection','Client Machine Authentication','Machine Policy Assignments Request',
                     'Machine Policy Evaluation','Refresh Default MP Task','LS (Location Service) Refresh Locations Task',
                     'LS (Location Service) Timeout Refresh Task','Policy Agent Request Assignment (User)',
                     'Policy Agent Evaluate Assignment (User)','Software Metering Generating Usage Report',
                     'Software Metering Generating Usage Report','Source Update Message','Clearing proxy settings cache',
                     'Machine Policy Agent Cleanup','User Policy Agent Cleanup','Policy Agent Validate Machine Policy / Assignment',
                     'Policy Agent Validate User Policy / Assignment','Retrying/Refreshing certificates in AD on MP','Peer DP Status reporting',
                     'Peer DP Pending package check schedule','SUM Updates install schedule','Hardware Inventory Collection Cycle',
                     'Software Inventory Collection Cycle','Discovery Data Collection Cycle','File Collection Cycle','IDMIF Collection Cycle',
                     'Software Metering Usage Report Cycle','Windows Installer Source List Update Cycle','Software Updates Assignments Evaluation Cycle',
                     'Branch Distribution Point Maintenance Task','Send Unsent State Message','State System policy cache cleanout','Scan by Update Source',
                     'Update Store Policy','State system policy bulk send high','State system policy bulk send low','Application manager policy action',
                     'Application manager user policy action','Application manager global evaluation action','Power management start summarizer',
                     'Endpoint deployment reevaluate','Endpoint AM policy reevaluate','External event detection')]
        [string[]]$Action,
 
        [Parameter(ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [Alias('hostname','PSComputerName')]
        [string[]]$ComputerName="$ENV:COMPUTERNAME",
 
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.Credential()]$Credential,
 
        [Parameter()]
        [switch]$List
    )
   
    BEGIN {
        # Trigger Calls
        $TriggerHashTable = @{
        'Hardware Inventory'='{00000000-0000-0000-0000-000000000001}'
        'Software Inventory'='{00000000-0000-0000-0000-000000000002}'
        'Data Discovery Record'='{00000000-0000-0000-0000-000000000003}'
        'File Collection'='{00000000-0000-0000-0000-000000000010}'
        'IDMIF Collection'='{00000000-0000-0000-0000-000000000011}'
        'Client Machine Authentication'='{00000000-0000-0000-0000-000000000012}'
        'Machine Policy Assignments Request'='{00000000-0000-0000-0000-000000000021}'
        'Machine Policy Evaluation'='{00000000-0000-0000-0000-000000000022}'
        'Refresh Default MP Task'='{00000000-0000-0000-0000-000000000023}'
        'LS (Location Service) Refresh Locations Task'='{00000000-0000-0000-0000-000000000024}'
        'LS (Location Service) Timeout Refresh Task'='{00000000-0000-0000-0000-000000000025}'
        'Policy Agent Request Assignment (User)'='{00000000-0000-0000-0000-000000000026}'
        'Policy Agent Evaluate Assignment (User)'='{00000000-0000-0000-0000-000000000027}'
        'Software Metering Generating Usage Report'='{00000000-0000-0000-0000-000000000031}'
        'Source Update Message'='{00000000-0000-0000-0000-000000000032}'
        'Clearing proxy settings cache'='{00000000-0000-0000-0000-000000000037}'
        'Machine Policy Agent Cleanup'='{00000000-0000-0000-0000-000000000040}'
        'User Policy Agent Cleanup'='{00000000-0000-0000-0000-000000000041}'
        'Policy Agent Validate Machine Policy / Assignment'='{00000000-0000-0000-0000-000000000042}'
        'Policy Agent Validate User Policy / Assignment'='{00000000-0000-0000-0000-000000000043}'
        'Retrying/Refreshing certificates in AD on MP'='{00000000-0000-0000-0000-000000000051}'
        'Peer DP Status reporting'='{00000000-0000-0000-0000-000000000061}'
        'Peer DP Pending package check schedule'='{00000000-0000-0000-0000-000000000062}'
        'SUM Updates install schedule'='{00000000-0000-0000-0000-000000000063}'
        'Hardware Inventory Collection Cycle'='{00000000-0000-0000-0000-000000000101}'
        'Software Inventory Collection Cycle'='{00000000-0000-0000-0000-000000000102}'
        'Discovery Data Collection Cycle'='{00000000-0000-0000-0000-000000000103}'
        'File Collection Cycle'='{00000000-0000-0000-0000-000000000104}'
        'IDMIF Collection Cycle'='{00000000-0000-0000-0000-000000000105}'
        'Software Metering Usage Report Cycle'='{00000000-0000-0000-0000-000000000106}'
        'Windows Installer Source List Update Cycle'='{00000000-0000-0000-0000-000000000107}'
        'Software Updates Assignments Evaluation Cycle'='{00000000-0000-0000-0000-000000000108}'
        'Branch Distribution Point Maintenance Task'='{00000000-0000-0000-0000-000000000109}'
        'Send Unsent State Message'='{00000000-0000-0000-0000-000000000111}'
        'State System policy cache cleanout'='{00000000-0000-0000-0000-000000000112}'
        'Scan by Update Source'='{00000000-0000-0000-0000-000000000113}'
        'Update Store Policy'='{00000000-0000-0000-0000-000000000114}'
        'State system policy bulk send high'='{00000000-0000-0000-0000-000000000115}'
        'State system policy bulk send low'='{00000000-0000-0000-0000-000000000116}'
        'Application manager policy action'='{00000000-0000-0000-0000-000000000121}'
        'Application Evaluation'='{00000000-0000-0000-0000-000000000121}' # Made a similar triger to 'Application manager policy action' for ease of use
        'Application manager user policy action'='{00000000-0000-0000-0000-000000000122}'
        'Application manager global evaluation action'='{00000000-0000-0000-0000-000000000123}'
        'Power management start summarizer'='{00000000-0000-0000-0000-000000000131}'
        'Endpoint deployment reevaluate'='{00000000-0000-0000-0000-000000000221}'
        'Endpoint AM policy reevaluate'='{00000000-0000-0000-0000-000000000222}'
        'External event detection'='{00000000-0000-0000-0000-000000000223}'
        }
        if ($List) { # write a list of client actions then breaks out of function
            $ListOutput = $TriggerHashTable | ForEach-Object {$_}
            $ListOutput
            break
        }
    }
    
    PROCESS {
        Foreach ($Computer in $ComputerName) {
            if ($Credential) {
                $Action | ForEach-Object {
                    try {
                        Write-Verbose "COMPUTER: $Computer TRIGGER: $($TriggerHashTable.$_)"
                        $Return = Invoke-WmiMethod -ComputerName "$Computer" -Credential $Credential -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule -ArgumentList $TriggerHashTable.$_ -ErrorAction Stop
                        Write-Verbose "WMI RETURNED COMPUTERNAME $($Return.PSComputerName)"
                        $OutputObject = New-Object -TypeName psobject -Property @{
                            'ComputerName'=$Return.PSComputerName
                            'Action'=$_
                            'Trigger'=$TriggerHashTable.$_
                            'Run Time'=(Get-Date)
                        }
                        Write-Output $OutputObject
                    }
                    catch {
                        Write-Error $PSItem
                    }
                }
            } else {
                $Action | ForEach-Object {
                    try {
                         Write-Verbose "COMPUTER: $Computer TRIGGER: $TriggerHashTable.$_"
                        $Return = Invoke-WmiMethod -ComputerName $Computer -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule -ArgumentList $TriggerHashTable.$_ -ErrorAction Stop
                        Write-Verbose "WMI RETURNED COMPUTERNAME $($Return.PSComputerName)"
                        $OutputObject = New-Object -TypeName psobject -Property @{
                            'ComputerName'=$Return.PSComputerName
                            'Action'=$_
                            'Trigger'=$TriggerHashTable.$_
                            'Run Time'=(Get-Date)
                        }
                        Write-Output $OutputObject
                    }
                    catch {
                        Write-Error $PSItem
                    }   
                }
            }
        }   
    }
}

Function Show-CCMUpdates {
    <#
        .SYNOPSIS
        Shows any known updates on target CCM Client

        .DESCRIPTION
        This Cmdlet is designed to check WMI to see if there are any updates known to the client. It returns the wmi object to pass to other cmdlets in the CCMClient Module.
        An example of a known update would be an update that is visible in Software Center. This function is a wrapper for: Get-WmiObject -Namespace root\ccm\clientsdk -Class CCM_SoftwareUpdate/
        If no updates are found the output will be a psobject with the computer name and the propery updates set to $false

        .PARAMETER ComputerName
        Specifies a computer name. More than one computer name is allowed to be passed. Pipeline values are also allowed.
        Type the NetBIOS name, the IP address, or the fully qualified domain name of the computer.

        .PARAMETER Credential
        Specifies a user account that has permission to perform this action.

        .PARAMETER Filter
        Species a key phrase to match against the title of updates

        .EXAMPLE
        Show-CMUpdates -ComputerName domain\remotehost -Credential domain\admin01

        .Example
        Get-CMUpdates

        .INPUTS
        System.String

        .OUTPUTS
        System.Management.Automation.PSCustomObject
        System.Management.ManagementObject 
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [Alias('hostname','PSComputerName')]
        [string[]]$ComputerName="$ENV:COMPUTERNAME",
        
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.Credential()]$Credential
    )
    Foreach ($Computer in $ComputerName){
        if ($Credential) {
            try {
                $ApplicableUpdates = Get-WmiObject -Namespace root\ccm\clientsdk -Class CCM_SoftwareUpdate -ComputerName "$Computer" -Credential $Credential
            } catch {
                Write-Error $PSItem
                $ApplicableUpdates = "ERROR"
            }
        } else {
            try {
                $ApplicableUpdates = Get-WmiObject -Namespace root\ccm\clientsdk -Class CCM_SoftwareUpdate -ComputerName "$Computer"
            } catch {
                Write-Error $PSItem
                $ApplicableUpdates = "ERROR"
            }
        }
        # output filters
        switch ($ApplicableUpdates){
            {$_ -eq $null}{$NullOutputObject = New-Object -TypeName psobject -Property @{
                'ComputerName'="$Computer"
                'Updates'=$False
                }
                Write-Output $NullOutputObject
            }
            {$_ -eq 'ERROR'}{#NO OUTPUT
            }
            default {Write-Output $ApplicableUpdates}
        }
    }
} 