Function Open-CCMSession {
    <#
        .SYNOPSIS
        Gets or creates a session to pass commands to Configuration Manager systems remotely.
 
        .DESCRIPTION
        This function is designed to check for an exisiting PSSession. If no session exists an attempt to create a session will be made.
        Three parameter sets are used. Credential, NoCredential, and Session. Credential attempts to get connections or start connections with passed credentials.
        NoCredential will do the same as Credential, just without -Credential passed. Session occurs when an existing connection is passed to the function.
        The output object will contain the necessary information for connections.

        .PARAMETER ComputerName
        Specifies a computer name. Only One computer name at a time can be passed. Type the NetBIOS name, the IP address, or the fully qualified domain name of the computer.

        .PARAMETER Credential 
        Specifies a user account or System.Management.Automation.Credential object that has permission to perform this action.

        .PARAMETER PSSession 
        PSSession allows a System.Management.Automation.Runspaces.PSSession object to be passed to the function to create a connection object.
        
        .INPUTS
        System.String
        System.Management.Automation.Runspaces.PSSession
        System.Management.Automation.Credential

        .OUTPUTS
        System.Management.Automation.Runspaces.PSSession
    #>
    [CmdletBinding(DefaultParameterSetName = 'NoCredential')]
    PARAM(
        [Parameter(Mandatory=$false,ParameterSetName='Session')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,

        [Parameter(Mandatory=$false,ParameterSetName='NoCredential')]
        [Parameter(Mandatory=$false, ParameterSetName='Credential')]
        [Alias('PSComputerName','IPAddress','ServerName','HostName')]
        [string]$ComputerName="$ENV:COMPUTERNAME",

        [Parameter(Mandatory=$false, ParameterSetName='Credential')]
        [ValidateNotNull()]
        [System.Management.Automation.Credential()]$Credential # () allows username only to be passed
    )
    $CurrentFunction = (Get-PSCallStack)[0].Command
    Write-Verbose "$CurrentFunction Current Param set: $($PSCmdlet.ParameterSetName)"
    switch ($PSCmdlet.ParameterSetName) {
        'Session' { # just pass back if for some reason a pssession is passed
            switch ($PSBoundParameters.Keys) {
                'PSSession' {
                    Write-Verbose "$CurrentFunction PSession passed. Setting OutputObject to PSSession"
                    $OutputObject = $PSSession
                }
            }
        }
        'NoCredential' { # if set no crendintial make attemtps without -credential 
            switch ($PSBoundParameters.Keys) {
                'ComputerName' {
                    Write-Verbose "$CurrentFunction ComputerName = $ComputerName"
                    if ("$ComputerName" -eq "$ENV:COMPUTERNAME") {
                        Write-Verbose "$CurrentFunction Passed Computer matches localhost: $ComputerName -eq $ENV:COMPUTERNAME"
                        Write-Verbose "$CurrentFunction CCMConnection set to empty"
                        $OutputObject = $null
                    } elseif ($PSSession = Get-PSSession -ComputerName $ComputerName -Name 'CCMSession' -ErrorAction Ignore) {
                        Write-Verbose "$CurrentFunction Found PSSession with name of 'CCMSession'"
                        Write-Verbose "$CurrentFunction Passing session to output"
                        $OutputObject = $PSSession
                    } else {
                        Write-Verbose "$CurrentFunction No session found"
                        try {
                          $PSSession = New-PSSession -ComputerName $ComputerName -Name 'CCMSession'
                          Write-Verbose "$CurrentFunction new CCMSession created"
                        } catch {
                            Write-Error $PSItem
                        }
                    }                        
                }
            }
        }
        'Credential' { # if a credential is passed make attemtpts with -credential
            switch ($PSBoundParameters.Keys) {
                'ComputerName' {
                    Write-Verbose "$CurrentFunction ComputerName = $ComputerName"
                    if ("$ComputerName" -eq "$ENV:COMPUTERNAME") {
                        Write-Verbose "$CurrentFunction Passed Computer matches localhost: $ComputerName -eq $ENV:COMPUTERNAME"
                        Write-Verbose "$CurrentFunction CCMConnection set to empty"
                        $OutputObject = $null
                    } elseif ($PSSession = Get-PSSession -ComputerName $ComputerName -Name 'CCMSession' -Credential $Credential -ErrorAction Ignore) {
                        Write-Verbose "$CurrentFunction Found PSSession with name of 'CCMSession'"
                        Write-Verbose "$CurrentFunction Passing session to output"
                        $OutputObject = $PSSession
                    } else {
                        Write-Verbose "$CurrentFunction No session found"
                        try {
                          $PSSession = New-PSSession -ComputerName $ComputerName -Name -Credential $Credential 'CCMSession'
                          Write-Verbose "$CurrentFunction new CCMSession created"
                        } catch {
                            Write-Error $PSItem
                        }
                    }
                }    
            }
        }
    }
    Write-Verbose "$CurrentFunction Returning Output object for Open-CCMSession"     
    return $OutputObject
}


Function Get-CCMLog {
    <#
        .SYNOPSIS
        Parses Configuration Manager Logs to provide an output similar to CMtrace, but in  powershell.
 
        .DESCRIPTION
        This function is designed to parse the raw data of Configuration Manager Logs and provide a similar experience to CMTrace in the shell.
        REGEX is applied to the raw data found in the log. REGEX Matches are then split into groupings that represent the diffrent fields in CMTrace.
        The REGEX groupings are then assigned to various properties and assigned to an output object. New lines are removed from the message text.
        The cmdlet is designed to parse only Configuration Manger Logs or logs written in the same raw data style. Best effort is given to other log
        formats. REGEX is used to look for key words: "Success","Info","Warning","Error". Type is assigned to the output so that -Filter is still
        effective and the output consistant.
       
        .PARAMETER Path
        Path to Target Configuration Manager Logs. More than one log path can be passed at a time.
 
        .PARAMETER LogGroup
        Get all client logs that are associated with a predefined log grouping.

        .PARAMETER Filter
        Filters based on the type of message in the log; "Success","Info","Warning","Error".
        
        .PARAMETER ComputerName
        Specifies a computer name. Only One computer name at a time can be passed.
        Type the NetBIOS name, the IP address, or the fully qualified domain name of the computer.
 
        .PARAMETER Credential
        Specifies a user account that has permission to perform this action.

        .PARAMETER InputObject
        Accepts strings to then process through REGEX and format in the desired output.

        .PARAMETER PSSession
        Accepts System.Management.Automation.Runspaces.PSSession objects if a preffred pssession is wanted for connection. If not defined, best efforts will be given on opening a new session.
 
        .EXAMPLE
        Get-CCMLog -Path "C:\Windows\CCM\Logs\PolicyAgent.log"
 
        .EXAMPLE
        Get-CCMLog -Path "C:\Windows\CCM\Logs\PolicyAgent.log","C:\Windows\CCM\Logs\ClientIDManagerStartup.log"
 
        .EXAMPLE
        Get-CCMLog -Path "C:\Windows\CCM\Logs\AppEnforce.log" -Filter Error
 
        .EXAMPLE
        Get-CCMLog -Path "C:\Windows\CCM\Logs\PolicyAgent.log" -ComputerName host.domain -Credential domain\admin01

        .EXAMPLE
        $InputObject = Get-Content -Path "C:\Windows\Logs\CBS\CBS.log"
        Get-CCMLog -InputObject $InputObject

        .EXAMPLE
        Get-Content -Path "C:\Windows\CCM\Logs\PolicyAgent.log" -Wait | Get-CCMLog
 
        .INPUTS
        System.String
 
        .OUTPUTS
        System.Management.Automation.PSCustomObject 

        .NOTES
        There is a diffrent formatting style between Server Logs and Client Logs. Server logs tend not to have
        a type to determine log severity. When a Server Log is passed best effor is used to determin severity. 
        This is the same case with non CCM logs. Only best effort is given to match the message to a known key word.
        ERROR and FAILED are used to determine severity ERROR.
        WARNING and CAUTION are used to determine severity WARNING.
        SUCCESS is used to determine severity SUCCESS.
        All non matches are determinied to be severity INFO.
        Log groups use alternitive regex look ups on client side logs.
    #>
    [CmdletBinding(DefaultParameterSetName='NoCredential')]
    PARAM(
        [Parameter(Mandatory=$false, ParameterSetName='NoCredential')]
        [Parameter(Mandatory=$false, ParameterSetName='Credential')]
        [Parameter(Mandatory=$false,ParameterSetName='Path')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter(Mandatory=$false, ParameterSetName='NoCredential')]
        [Parameter(Mandatory=$false, ParameterSetName='Credential')]
        [Parameter(Mandatory=$false,ParameterSetName='LogGroup')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Application Management","Client Registration","Inventory","Policy","Software Updates","Software Distribution","Desired Configuration Management","Operating System Deployment")]
        [string]$LogGroup,

        [Parameter(Mandatory=$false, ParameterSetName='NoCredential')]
        [Parameter(Mandatory=$false, ParameterSetName='Credential')]
        [Parameter(Mandatory=$false,ParameterSetName='Input')]
        [Parameter(Mandatory=$false, ParameterSetName='Path')]
        [Parameter(Mandatory=$false,ParameterSetName='LogGroup')]
        [ValidateSet("Success","Info","Warning","Error")]
        [string]$Filter,

        [Parameter(Mandatory=$false, ParameterSetName='NoCredential')]
        [Parameter(Mandatory=$false, ParameterSetName='Credential')]
        [Parameter(Mandatory=$false, ParameterSetName='Path')]
        [Parameter(Mandatory=$false,ParameterSetName='LogGroup')]
        [ValidateNotNullOrEmpty()]
        [Alias('hostname','PSComputerName')]
        [string]$ComputerName="$ENV:COMPUTERNAME",

        [Parameter(Mandatory=$false, ParameterSetName='Credential')]
        [Parameter(Mandatory=$false, ParameterSetName='Path')]
        [Parameter(Mandatory=$false,ParameterSetName='LogGroup')]
        [ValidateNotNull()]
        [System.Management.Automation.Credential()]$Credential,

        [Parameter(Mandatory=$false,ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,ParameterSetName='Input')]
        [string[]]$InputObject,

        [Parameter(Mandatory=$false, ParameterSetName='NoCredential')]
        [Parameter(Mandatory=$false, ParameterSetName='Credential')]
        [Parameter(Mandatory=$false, ParameterSetName='Path')]
        [Parameter(Mandatory=$false,ParameterSetName='LogGroup')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )

    BEGIN {
        $CurrentFunction = (Get-PSCallStack)[0].Command
        Write-Verbose "$CurrentFunction Begin block begin"
         <################
        # Client Pattern #
        ##################
        Group 1 = Message
        Group 4 = Time
        Group 6 = Date
        Group 8 = Component
        Group 10 = Type
        Group 12 = Thread
        Group 14 = File
        '(?s)<!\[LOG\[(.*?)(\]LOG\])(.*?time=")(\d\d\D\d\d\D\d\d\D\d\d\d)(.*?date=")(\d\d\D\d\d\D\d\d\d\d)(".component=")(.*?)(\".context="".type=")(\d)(".thread=")(.*?)(".file=")(.*?)[^!]>'
        Groups           1      2      3                   4                 5                  6              7           8          9               10       11     12       13   14  
        #################>
        $ClientPattern = '(?s)<!\[LOG\[(.*?)(\]LOG\])(.*?time=")(\d\d\D\d\d\D\d\d\D\d\d\d)(.*?date=")(\d\d\D\d\d\D\d\d\d\d)(".component=")(.*?)(\".context="".type=")(\d)(".thread=")(.*?)(".file=")(.*?)[^!]>'
        Write-Verbose "$CurrentFunction Client pattern = $ClientPattern"
        <#################
        # Server Pattern # may need to add (?s) if new lines become an issue...
        ##################
        Group 1 = Message
        Group 3 = Component
        Group 5 = Date\Time
        Group 10 = Thread
        '(.*?)(\$\$<.*?)(.*?)(><)(.*?)(\+)(.*?)(><)(thread=)(.*?)>'
            1   2         3    4    5   6   7    8   9        10
        #>################
        $ServerPattern = '(.*?)(\$\$<.*?)(.*?)(><)(.*?)(\+)(.*?)(><)(thread=)(.*?)>'
        Write-Verbose "$CurrentFunction Server pattern = $ServerPattern"
        # Best effort Patterns
        $SuccessFilter = '\b(Success | SUCCESS)\b'
        $WarningFilter = '\b(Warning | Caution | WARNING | CAUTION)\b'
        $ErrorFilter = '\b(Error | Failed | ERROR | FAILED)\b'
        # Do some validation for needful checks and warnings
        Write-Verbose "$CurrentFunction Current Param set: $($PSCmdlet.ParameterSetName)"
        if ($Path) { # path checks
            $Path | ForEach-Object -Process {
                $logext = [IO.Path]::GetExtension($Path)
                if ($logext -eq ".log") {
                    Write-Verbose "$CurrentFunction .log is accepted ext. $_"
                } elseif ($logext -eq ".lo_") {
                    Write-Verbose "$CurrentFunction .lo_ is valid ext. $_"
                } elseif ($InputObject) {
                    # Do nothing as an input object means we are accepting values from pipeline
                } else {
                    Write-Verbose "$CurrentFunction $_"
                    Write-Warning "Extension $logext is not valid .log or .lo_ extension type."
                }    
            }
        }
        if ($LogGroup) { # loggroup values
            if ($PSBoundParameters.ContainsKey('Path') -and $PSBoundParameters.ContainsKey('LogGroup')) { # quick validation for log group and path
                Write-Error "Path and LogGroup cannot be used together."
                return
            }
            <#############
            # Log Groups #
            #############>
            $CCMClientLogPath = "$ENV:SYSTEMROOT\CCM\Logs\"
            Write-Verbose "$CurrentFunction Setting CCMCLientLogPath to $CCMClientLogPath"
            $LogGroupHashTable = @{
                'Application Management'='^(app.*|ci.*|contentaccess|contenttransfermanager|datatransferservice|dcm.*|execmgr.*|UserAffinity.*|.*Handler$|.*Provider$)'
                'Client Registration'='^(clientregistration|locationservices|ccmmessaging|ccmexec)'
                'Inventory'='^(ccmmessaging|inventoryagent|mtrmgr|swmtrreportgen|virtualapp|mtr.*|filesystemfile)'
                'Policy'='^(ccmmessaging|policyagent_.*|policyevaluator_.*)'
                'Software Updates'='^(ci.*|contentaccess|contenttransfermanager|datatransferservice|dcm.*|update.*|wuahandler|xmlstore|scanagent)'
                'Software Distribution'='^(datatransferservice|execmgr.*|contenttransfermanager|locationservices|contentaccess|filebits)'
                'Desired Configuration Management'='Desired Configuration Management" value="^(ci.*|dcm.*)'
                'Operating System Deployment'='^(ts.*)'
            }
            Write-Verbose "$CurrentFunction LogGroupHashTableREGEX = $LogGroupHashTable"
        }
        if ($Credential) {
            if ($ENV:COMPUTERNAME -eq $ComputerName) {
                Write-Error "-Credential cannot be used on localhost"
                return
            }
            if ($PSBoundParameters.ContainsKey('Credential') -and $PSBoundParameters.ContainsKey('PSSession')) { # quick validation for log group and path
                Write-Error "Credential and PSSession cannot be used together."
                return
            }
        }
        if ($Input) {
            $LogContent = $InputObject
        }
        Write-Verbose "$CurrentFunction Begin block end"
    }
    PROCESS {
        Write-Verbose "$CurrentFunction Process block begin"
        Write-Verbose "$CurrentFunction Current Param set: $($PSCmdlet.ParameterSetName)"
        # call out to open-ccmsession to get connection point
        $CCMSession = $null
        try {
            if ($Credential) {
                $CCMSession = Open-CCMSession -ComputerName $ComputerName -Credential $Credential
            } elseif ($PSSession) {
                $CCMSession = Open-CCMSession -PSSession $PSSession
            } else {
                $CCMSession = Open-CCMSession -ComputerName $ComputerName
            }
        } catch {
            Write-Error "Unable to make a connection point to $ComputerName"
            $PSItem
            return
        }
        # Establish LogContent
        switch ($PSBoundParameters.Keys) {
            'Path' {
                try {
                    if ($CCMSession) {
                        $LogContent = Invoke-Command -Session $CCMSession -ScriptBlock {Get-Content -Path $Using:Path}
                    } else {
                        $LogContent = Get-Content -Path $Path   
                    }
                } catch {
                    $PSItem
                }
            }
            'LogGroup' {
                try {
                    if ($CCMSession) {
                        $LogContent = Invoke-Command -Session $CCMSession -ScriptBlock {
                            $CCMClientLogs = Get-ChildItem -Path $Using:CCMClientLogPath | Select-Object -ExpandProperty Name
                            $LogGroupHashTable = $Using:LogGroupHashTable
                            $LogGroup = $Using:LogGroup
                            $CCMCLientLogMatches = $CCMClientLogs -match $LogGroupHashTable.$LogGroup
                            $ContentPath = $CCMCLientLogMatches | ForEach-Object {"$Using:CCMClientLogpath$_"}
                            Get-Content -Path $ContentPath
                        }
                    } else {
                        $CCMClientLogs = Get-ChildItem -Path $CCMClientLogPath | Select-Object -ExpandProperty Name
                        $CCMCLientLogMatches = $CCMClientLogs -match $LogGroupHashTable.$LogGroup
                        $ContentPath = $CCMCLientLogMatches | ForEach-Object {"$CCMClientLogpath$_"}
                        Get-Content -Path $ContentPath
                    }
                } catch {
                    $PSItem
                }
            }
            'Input' {
                #$LogContent = $InputObject
            }
        }

        # Client Regex Checks
        $ClientRegexMatches = [regex]::Matches($LogContent, $ClientPattern)
        # Server Regex Checks
        $ServerRegexMatches = [regex]::Matches($LogContent, $ServerPattern)

        if ($ClientRegexMatches.Count -gt 0) { # cient regex
            $ClientRegexMatches | ForEach-Object {
                $DateTime = "$($_.Groups[6].Value) $($_.Groups[4].Value)"
                Write-Verbose "$CurrentFunction $DateTime"
                $DateTime = [datetime]::ParseExact($DateTime, 'MM-dd-yyyy HH:mm:ss.fff', $null)
                $Message = $_.Groups[1].Value
                $Message = $Message -replace '\r?\n', ' '
                $Type = $_.Groups[10].Value
                $Component = $_.Groups[8].Value
                $Thread = $_.Groups[12].Value
                $File = $_.Groups[14].Value
                # translate type to error value
                switch ($Type) {
                    '1' {$Type = 'Info'}
                    '0' {$Type = 'Success'}
                    '2' {$Type = 'Warning'}
                    '3' {$Type = 'Error'}
                    default {$Type = 'Unknown'}
                }
                # Create output object
                $OutputObject = New-Object -TypeName psobject -Property @{
                    'Date\Time' = $DateTime
                    'Message' = $Message
                    'Severity' = $Type
                    'Component' = $Component
                    'Thread' = $Thread
                    'File' = $File
                }
                switch ($Filter) {
                    'Info' {if ($Type -eq 'Info') {Write-Output $OutputObject}}
                    'Success' {if ($Type -eq 'Success') {Write-Output $OutputObject}}
                    'Warning' {if ($Type -eq 'Warning') {Write-Output $OutputObject}}
                    'Error' {if ($Type -eq 'Error') {Write-Output $OutputObject}}
                    default {Write-Output $OutputObject}
                }
            }
        } elseif ($ServerRegexMatches.Count -gt 0) { # server regex
            $ServerRegexMatches | ForEach-Object {
                $DateTime = $_.Groups[5].Value
                $DateTime = [datetime]::ParseExact($DateTime, 'MM-dd-yyyy HH:mm:ss.fff', $null)
                $Message = $_.Groups[1].Value
                $Message = $Message -replace '\r?\n', ' '
                $Component = $_.Groups[3].Value
                $Thread = $_.Groups[10].Value
                $File = $null
                # best effort on Severity
                Write-Verbose "$CurrentFunction WARNING: No REGEX matches on TYPE, giving best effort"
                $Message | ForEach-Object {
                    if ($_ -match $ErrorFilter) {
                        $Type = 'Error'
                    } elseif ($_ -match $WarningFilter) {
                        $Type = 'Warning'
                    } elseif ($_ -match $SuccessFilter) {
                        $Type = 'Success'
                    } else {
                        $Type = 'Info'
                    }
                }
                # Create output object
                $OutputObject = New-Object -TypeName psobject -Property @{
                    'Date\Time' = $DateTime
                    'Message' = $Message
                    'Severity' = $Type
                    'Component' = $Component
                    'Thread' = $Thread
                    'File' = $File
                }
                switch ($Filter) {
                    'Info' {if ($Type -eq 'Info') {Write-Output $OutputObject}}
                    'Success' {if ($Type -eq 'Success') {Write-Output $OutputObject}}
                    'Warning' {if ($Type -eq 'Warning') {Write-Output $OutputObject}}
                    'Error' {if ($Type -eq 'Error') {Write-Output $OutputObject}}
                    default {Write-Output $OutputObject}
                }
            }
        } else { # best effor on log
            Write-Verbose "$CurrentFunction WARNING: No REGEX matches on server and client, giving best effort"
            $DateTime = $null
            $Component = $null
            $Thread = $null
            $File = $null
            $LogContent | ForEach-Object {
                $Message = $_
                if ($_ -match $ErrorFilter) {
                    $Type = 'Error'
                } elseif ($_ -match $WarningFilter) {
                    $Type = 'Warning'
                } elseif ($_ -match $SuccessFilter) {
                    $Type = 'Success'
                } else {
                    $Type = 'Info'
                }
                # Create output object
                $OutputObject = New-Object -TypeName psobject -Property @{
                    'Date\Time' = $DateTime
                    'Message' = $Message
                    'Severity' = $Type
                    'Component' = $Component
                    'Thread' = $Thread
                    'File' = $File
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
        Write-Verbose "$CurrentFunction Process Block End"
    }
}
 
Function Invoke-CCMClientAction {
    <#
        .SYNOPSIS
        Invokes CCM Clients to run a desired action
 
        .DESCRIPTION
        This function is designed to invoke WMI trigger actions on a local or remote system. This is similar to the Configuration Manager Applet found in Control Panel.
        Elevated permissions may be needed to access the namespace for the local or target system. This function creates a wrapper for
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
        $CurrentFunction = (Get-PSCallStack)[0].Command
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
                        Write-Verbose "$CurrentFunction COMPUTER: $Computer TRIGGER: $($TriggerHashTable.$_)"
                        $Return = Invoke-WmiMethod -ComputerName "$Computer" -Credential $Credential -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule -ArgumentList $TriggerHashTable.$_ -ErrorAction Stop
                        Write-Verbose "$CurrentFunction WMI RETURNED COMPUTERNAME $($Return.PSComputerName)"
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
                         Write-Verbose "$CurrentFunction COMPUTER: $Computer TRIGGER: $TriggerHashTable.$_"
                        $Return = Invoke-WmiMethod -ComputerName $Computer -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule -ArgumentList $TriggerHashTable.$_ -ErrorAction Stop
                        Write-Verbose "$CurrentFunction WMI RETURNED COMPUTERNAME $($Return.PSComputerName)"
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
        This function is designed to check WMI to see if there are any updates known to the client. It returns the wmi object to pass to other functions if desired.
        An example of a known update would be an update that is visible in Software Center. This function is a wrapper for: Get-WmiObject -Namespace root\ccm\clientsdk -Class CCM_SoftwareUpdate.
        If no updates are found the output will be a psobject with the computer name and the propery updates set to $false. This cmdlet is designed to show available updates and not scan against
        SUPs to get new updates.

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
    $CurrentFunction = (Get-PSCallStack)[0].Command
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
        Foreach ($Update in $ApplicableUpdates) {
            switch ($Update){
                {$_ -eq $null}{$NullOutputObject = New-Object -TypeName psobject -Property @{
                    'ComputerName'="$Computer"
                    'Updates'=$False
                    }
                    Write-Output $NullOutputObject
                }
                {$_ -eq 'ERROR'}{#NO OUTPUT
                }
                default {Write-Output $_}
            }  
        } 
    }
} 

Function Write-CCMLog {
    <#
    .SYNOPSIS
    Function to write logs that can be parsed with CmTrace.exe and Get-CCMLog.

    .DESCRIPTION
    This function strives to mimic the logging experience of Configuration Manager. The output from Write-CCMLog is in the same format as the logs produced by Configuration Manager. This allows 
    cmtrace.exe to easily parse and understand the information in the log. Other functions in this module, such as Get-CCMLog also use regex to parse against the same log formats. 

    .PARAMETER Message
    Passed string to write to log. Accepts string input for piping messages.

    .PARAMETER Severity
    Passed severity level to highlight when viewing with CMtrace or to categorize with Get-CCMLog. Valid values are "Success","Info","Warning","Error". The default value is Info.

    .PARAMETER Component
    Passed string to fill the Component column. The default value is MyInvocation.MyCommand.Name

    .PARAMETER LogPath
    Passed string to decide log output. The default is "$ENV:Temp\CCMClient.log".

    .EXAMPLE
    Write-CCMLog -Message "Info: This is the start of the log"

    .EXAMPLE
    Write-CCMLog -Message "Warning: This is a warning in the middle of the log" -Severity Warning -Component "PROCESS"

    .EXAMPLE
    Write-CCMLog -Message "Error: This is a terminiating error for some process that needs to be logged in C:\... $SomeProcessPassedExitCode" -Severity Error -Component "END" -LogPath C:\MyErrors.Log
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory = $true,ValueFromPipeline = $True)]
        [String]$Message,

        [Parameter()]
        [ValidateSet("Success","Info","Warning","Error")]
        [String]$Severity='Info',

        [Parameter()]
        [string]$Component=$MyInvocation.MyCommand.Name,

        [Parameter()]
        [string]$LogPath="$ENV:Temp\CCMClient.log"
    )
    switch ($Severity) {
        'Info' {[int]$Type = 1}
        'Success' {[int]$Type = 0}
        'Warning' {[int]$Type = 2}
        'Error' {[int]$Type = 3}
        default {[int]$Type = 1}
    }
        $DecThread = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        $HexThread = '{0:x}' -f $DecThread
        $Thread = "$DecThread (0x$HexThread)" # not 100% sure this is the correct logic...
        $TimeZoneBias = Get-WMIObject -Query "Select Bias from Win32_TimeZone"
        $Date= Get-Date -Format "HH:mm:ss.fff"
        $Date2= Get-Date -Format "MM-dd-yyyy"   
        "<![LOG[$Message]LOG]!><time=$([char]34)$Date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$Component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$Type$([char]34) thread=$([char]34)$Thread$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $LogPath -Append -NoClobber -Encoding default
}