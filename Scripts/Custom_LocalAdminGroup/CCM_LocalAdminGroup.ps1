###############################################################################
# # Author: Sam                                                             # #
# # Script: CCM_LocalAdminGroup.ps1                                         # #
# # Goal:   to add a custom wmi class for local admin details via CI        # #
###############################################################################


########
# Vars #
########
$CCM_LocalAdminGroup = "CCM_LocalAdminGroupDetails"
$LocalAdminGroup = Get-LocalGroup -Name Administrators | Select-Object -Property *
$Members = Get-LocalGroupMember -Name Administrators | Select-Object -Property *

#############
# Functions #
#############
Function Create-CCMLocalAdminGroup { 
    $New_CCM_LocalAdminGroup = New-Object System.Management.ManagementClass ("root\cimv2", [String]::Empty, $Null); 
    $New_CCM_LocalAdminGroup['__CLASS'] = $CCM_LocalAdminGroup
    $New_CCM_LocalAdminGroup.Properties.Add("Account",[System.Management.CimType]::String, $false)
    $New_CCM_LocalAdminGroup.Properties["Account"].Qualifiers.Add("Key", $true)
    $New_CCM_LocalAdminGroup.Properties.Add("Domain",[System.Management.CimType]::String, $false)
    $New_CCM_LocalAdminGroup.Properties.Add("SID",[System.Management.CimType]::String, $false)
    $New_CCM_LocalAdminGroup.Properties.Add("PrincipalSource",[System.Management.CimType]::String, $false)
    $New_CCM_LocalAdminGroup.Properties.Add("ObjectClass",[System.Management.CimType]::String, $false)
    $New_CCM_LocalAdminGroup.Properties.Add("Enabled",[System.Management.CimType]::String, $false)
    $New_CCM_LocalAdminGroup.Properties.Add("PasswordLastSet",[System.Management.CimType]::String, $false)
    $New_CCM_LocalAdminGroup.Put() | Out-Null
} 

########
# MAIN #
########
$CreateCCM_LocalAdminGroup = Create-CCMLocalAdminGroup
Get-WmiObject -Namespace root\cimv2 -class $CCM_LocalAdminGroup | Remove-WMIOBject # having issues updating based on key values.. simply wiping old instances on rerun then populating current values...
ForEach ($Member in $Members) {
    $GetLocalUser = $null
    $PasswordLastSet = $null
    $Enabled = $null
    # we are only checking for local accounts for enabled and passwordsettings
    if (($Member.PrincipalSource -eq 'Local') -and ($Member.ObjectClass -eq 'User')) { 
        $GetLocalUser = Get-LocalUser -SID $Member.SID | Select-Object *
        $PasswordLastSet = $GetLocalUser.PasswordLastSet
        $Enabled = $GetLocalUser.Enabled    
    }
    Set-WmiInstance -Namespace root\cimv2 -class $CCM_LocalAdminGroup -arguments @{
        Account = $Member.Name
        Domain = $env:USERDOMAIN
        SID = $Member.SID
        PrincipalSource = $Member.PrincipalSource
        ObjectClass = $Member.ObjectClass
        Enabled = $Enabled
        PasswordLastSet = $PasswordLastSet
    } | Out-Null
}   

# Exit
######
$ClassExists = Get-WmiObject -Namespace root\cimv2 -class $CCM_LocalAdminGroup
If ($ClassExists) {
    Write-Output 0
} else {
    Write-Output 1
}