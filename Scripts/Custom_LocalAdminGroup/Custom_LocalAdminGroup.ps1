# DC Check
if ( (Get-CimInstance -ClassName win32_computerSystem -Namespace 'root\cimv2').DomainRole -in (4,5)) { 
    exit 0
}

########
# Vars #
########
$Custom_LocalAdminGroup = "CCM_LocalAdminGroupDetails"
$Today = Get-Date
$CIBaselineRunTime = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($Today) # converted to allow WMI insert
$LocalAdminGroup = Get-LocalGroup -Name Administrators | Select-Object -Property *
$Members = Get-LocalGroupMember -Name Administrators | Select-Object -Property *
$ExitCode = 0 # Exit code to check for on CI 0 = Success / Other than 0 = Failure

#############
# Functions #
#############
Function Create-CustomLocalAdminGroup { 
    # NEED TO ADJUST 5/29
    $New_Custom_LocalAdminGroup = New-Object System.Management.ManagementClass ("root\cimv2", [String]::Empty, $Null); 
    $New_Custom_LocalAdminGroup['__CLASS'] = $Custom_LocalAdminGroup
    $New_Custom_LocalAdminGroup.Properties.Add("Account",[System.Management.CimType]::String, $false)
    $New_Custom_LocalAdminGroup.Properties["Account"].Qualifiers.Add("Key", $true)
    $New_Custom_LocalAdminGroup.Properties.Add("Domain",[System.Management.CimType]::String, $false)
    $New_Custom_LocalAdminGroup.Properties["Domain"].Qualifiers.Add("Key", $true)
    $New_Custom_LocalAdminGroup.Properties.Add("PrincipalSource",[System.Management.CimType]::String, $false)
    $New_Custom_LocalAdminGroup.Properties.Add("Type",[System.Management.CimType]::String, $false)
    $New_Custom_LocalAdminGroup.Properties.Add("Name",[System.Management.CimType]::String, $false)
    $New_Custom_LocalAdminGroup.Properties["Name"].Qualifiers.Add("Key", $true)
    $New_Custom_LocalAdminGroup.Properties.Add("Enabled",[System.Management.CimType]::string, $false)
    $New_Custom_LocalAdminGroup.Properties.Add("SID",[System.Management.CimType]::string, $false)
    $New_Custom_LocalAdminGroup.Properties.Add("GroupSID",[System.Management.CimType]::string, $false)
    $New_Custom_LocalAdminGroup.Properties.Add("CIBaselineLastRan",[System.Management.CimType]::DateTime, $false)
    $New_Custom_LocalAdminGroup.Put() | Out-Null
} 

########
# MAIN #
########
$CreateCustom_LocalAdminGroup = Create-CustomLocalAdminGroup
ForEach ($Member in $Members) {
    $Name = $Member.Name
    $PrincipalSource = $Member.PrincipalSource
    $SID = $Member.SID
    $Enabled = Get-LocalUser -SID $SID | Select-Object -ExpandProperty Enabled

    <# NEED TO ADJUST 5/29
    Set-WmiInstance -Namespace root\cimv2 -class $Custom_LocalAdminGroup -arguments @{
        Account = $name
        Domain = $Domain
        PrincipalSource = $PrincipalSource
        SID = $SID
        GroupSID = (Get-LocalGroup -Name $TheName.Name).SID
        Type = $Type
        Name = $TheName.Name
        CIBaselineLastRan=$CIBaselineRunTime
        Enabled = $Enabled.Enabled
    } | Out-Null
    #>
}







    