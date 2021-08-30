<#
    .SYNOPSIS
    Finds and deletes VM snapshots. 

    .DESCRIPTION
    The purpose of this script is to remove VM snapshots that are older than 30 days. Then send an email report showing all of the snapshots that were deleted. 

    .PARAMETER vCenter
    The vcenter you want to target for removing snaps
    
    .PARAMETER ToAdress
    The email address for the report to be sent to.  

    .NOTES
    Author: Jeremy Jones
    Sever and vcenters names used for demonstration purposes only. 

    .EXAMPLE
    Remove-OldSnapshots -vcenter myvcenter.vsphere.local -ToAddres Jeremy.jones@Joneslab.com
#>


param(
    [Parameter(Mandatory = $true)]
    [string]$vcenter,
    [Parameter(Mandatory = $true)}]
    [string]$ToAddress 
)

# Storing credential file for authentication
$mycred = Get-Credential

#------- Snap-in imports -------#
Import-Module VMware.Powercli

#------- Set to address and subject -------#
$Subject = "Deleted VM Snapshots Report"

#Setting up arrays
$AllSnaps = @()
$DeleteSnaps = @()
$SnapReport = @()
$HTMLSnaps = @()

#creating date stamp for report
$Date = Get-date 
$Date = $date.ToString('MM-dd_hh-mm')

#Connecting to vCenter
Connect-VIServer -Server $vcenter -Credential $mycred

#Gathering all Snapshot information from vcenter adding expression to easily identify 30 day old snapshots
$AllSnaps = get-snapshot -vm * | select-object VM, Name, Description, SizeMB, @{Name="Age";Expression={((Get-Date)-$_.Created).Days}}

#Deleting 30 day old snapshots
$DeleteSnaps = $AllSnaps | where {($_.age -gt 29)}

if ($deleteSnaps -ne $null){
    foreach($snap in $DeleteSnaps){
    Remove-Snapshot -Snapshot $snap -Confirm:$false
    }
}else {
    write-host "No Snapshots to clean up" -ForegroundColor Red
}

#Creating email Report and sending
$SnapReport = $DeleteSnaps | Select-Object VM, Name, Description, SizeMB, Age 

$HTMLSnaps = $SnapReport | ConvertTo-Html | Out-String

$report | Export-Csv .\output\report_$date.csv -NoTypeInformation 

Send-MailMessage -To $ToAddress -Subject $Subject `
  -SmtpServer smtp.Joneslab.com  -From ProdReports@joneslab.com `
  -BodyAsHtml -Body $HTMLSnaps 

#Disconnecting from vcenter after all operations are complete
Disconnect-VIServer -Server $vcenter -confirm:$false