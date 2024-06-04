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
    $New_Custom_LocalAdminGroup.Properties.Add("SID",[System.Management.CimType]::String, $false)
    $New_Custom_LocalAdminGroup.Properties.Add("PrincipalSource",[System.Management.CimType]::String, $false)
    $New_Custom_LocalAdminGroup.Properties.Add("ObjectClass",[System.Management.CimType]::String, $false)
    $New_Custom_LocalAdminGroup.Properties.Add("Enabled",[System.Management.CimType]::String, $false)
    $New_Custom_LocalAdminGroup.Properties.Add("PasswordLastSet",[System.Management.CimType]::String, $false)
    $New_Custom_LocalAdminGroup.Put() | Out-Null
} 

########
# MAIN #
########
$CreateCustom_LocalAdminGroup = Create-CustomLocalAdminGroup
ForEach ($Member in $Members) {
    # we are only checking for local accounts for enabled and passwordsettings
    if (($Member.PrincipalSource -eq 'Local') -and ($Member.ObjectClass -eq 'User')) {
        $GetLocalUser = $null
        $PasswordLastSet = $null
        $Enabled = $null
        $GetLocalUser = Get-LocalUser -SID $Member.SID | Select-Object *
        $PasswordLastSet = $GetLocalUser.PasswordLastSet
        $Enabled = $GetLocalUser.Enabled    
    }
    Set-WmiInstance -Namespace root\cimv2 -class $Custom_LocalAdminGroup -arguments @{
        Account = $Member.Name
        Domain = $env:USERDOMAIN
        SID = $Member.SID
        PrincipalSource = $Member.PrincipalSource
        ObjectClass = $Member.ObjectClass
        Enabled = $Enabled
        PasswordLastSet = $PasswordLastSet
    } | Out-Null  
}







    