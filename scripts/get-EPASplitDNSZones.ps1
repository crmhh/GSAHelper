<#
    .NOTES
        Written by Chris Brumm in June 2024
        Inspired by Callan Halls-Palmer: https://hallspalmer.wordpress.com/2020/04/22/report-on-dns-policy-with-powershell/
    .SYNOPSIS
        Lists all DNS server policies and its configuration details for the given server.
    .DESCRIPTION
        Lists all DNS server policies and its configuration details for the given server. 
        Since DNS policies are configured and stored per server you should query all relevant server.
    .PARAMETER DNSServer
        ...
    .EXAMPLE
        .\get-EPASplitDNSZones -ZoneName "exclusion3.gkfelucia.net" -PubIP "162.55.0.123" -PrivIP "192.168.0.21"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false, HelpMessage = '...')]
    [string] $DNSServer = $env:computername
)

#$DNSServer = "gkfeluciadc1.gkfelucia.net"
$Result= @()
$Zones = (Get-DnsServerZone | where {$_.isAutoCreated -eq $false}).ZoneName
foreach ($Zone in $Zones) {
    $Policy = Get-DnsServerQueryResolutionPolicy -ZoneName $Zone -ComputerName $DNSServer
    if ($Policy.IsEnabled -eq "True") {
        $Criteria = Get-DnsServerQueryResolutionPolicy -ZoneName $Zone -Name $Policy.Name -ComputerName $DNSServer | Select -ExpandProperty Criteria
        $Content = Get-DnsServerQueryResolutionPolicy -ZoneName $Zone -Name $Policy.Name -ComputerName $DNSServer| Select -ExpandProperty Content
        $ZoneScope = $Content.ScopeName
        $PolName = $Policy.Name
        $Action = $Policy.Action
        $Filter = ($Criteria.Criteria.Split(","))[0]
        $ProcOrder = $Policy.ProcessingOrder
        $ClientSubnet = ($Criteria.Criteria.Split(","))[1]
        $ClientSubnetObj = Get-DnsServerClientSubnet -Name $ClientSubnet -ComputerName $DNSServer
        ForEach($Subnet in $ClientSubnetObj){
            $Subnets = (@($Subnet.IPV4Subnet) -join ", ")
        }
        $PrivIP = (Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType "A" -Name "@").RecordData.IPv4Address.IPAddressToString
        $PubIP =  (Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType "A" -Name "@" -ZoneScope $ZoneScopeName).RecordData.IPv4Address.IPAddressToString
    $Result += [PSCustomOBject]@{
        DNSServer = $Server 
        PolicyName = $PolName 
        ZoneName = $Zone 
        ZoneScope = $ZoneScope 
        QueryFilter = $Filter 
        Action = $Action 
        ClientSubnetName = $ClientSubnet 
        IPv4Subnets = $Subnets 
        ProcessingOrder = $ProcOrder 
        InternalIP = $PrivIP
        ExternalIP = $PubIP
        }
    }
}
$Result
