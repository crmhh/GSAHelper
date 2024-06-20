<#
    .NOTES
        Written by Chris Brumm in June 2024
    .SYNOPSIS
        Creates a new Subdomain for a split DNS record including DNS policies for Entra Private Access
    .DESCRIPTION
        This script will create a new PinPoint subdomain for split DNS scenarios. 
        For this subdomain a DNS policy will be created and assigned. 
        This policy will allow the DNS server to reply with different values for requests from Entra Private Access clients.
        As a prereq for this you have to create a DnsServerClientSubnet with the IPs of your Entra Private Connectors.
    .PARAMETER ZoneName
        This is the FQDN of your exclusion, eg. "exclusion.contoso.com"
    .PARAMETER PubIP
        This is the public IP and is mandatory
    .PARAMETER PrivIP
        This is the private IP and is mandatory
    .PARAMETER ZoneScopeName
        This is the name of the DNS scope. This parameter is optional and if you don't override it, it will be set as "EPA-Exclusion"
    .PARAMETER Connectors
        To distinct internal requests from requests from Entra Private Access Clients 
        we need a DnsServerClientSubnet configuration including the IPs of your Entra Private Connectors.
        You can create this config with this CMDlets:
            Add-DnsServerClientSubnet -Name $Connectors -IPv4Subnet "192.168.0.40/32" -PassThru
            Set-DnsServerClientSubnet -Name $Connectors -Action ADD -IPv4Subnet "192.168.0.41/32" -PassThru
        This parameter is optional and if you don't override it, it will be set as "EPA-Exclusion"
    .EXAMPLE
        .\new-EPASplitDNSZone -ZoneName "exclusion.contoso.com" -PubIP "<YouPublicIP>" -PrivIP "<YourPrivateIP>"
    .EXAMPLE
        .\new-EPASplitDNSZone -ZoneName "exclusion.contoso.com" -PubIP "<YouPublicIP>" -PrivIP "<YourPrivateIP>" -ZoneScopeName "EPA-Exclusion" -Connectors "EntraPrivateNetworkConnector"
#>

#Requires -Version 4.0

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true, HelpMessage = 'The FQDN of your split DNS record')]
    [string] $ZoneName,
    [Parameter(Mandatory = $false, HelpMessage = 'The name of the used scope')]
    [string] $ZoneScopeName = "EPA-Exclusion",
    [Parameter(Mandatory = $false, HelpMessage = 'The config including your Entra Network Connector IPs')]
    [string] $Connectors = "EntraPrivateNetworkConnector",
    [Parameter(Mandatory = $true, HelpMessage = 'The public IP of your FQDN')]
    [string] $PubIP,
    [Parameter(Mandatory = $false, HelpMessage = 'The private IP of your FQDN')]
    [string] $PrivIP

)

# Create the Zone for the FQDN
Add-DnsServerPrimaryZone -Name $ZoneName -ReplicationScope "Forest" -PassThru

# Create ZoneScope for the Zone
Add-DnsServerZoneScope -ZoneName $ZoneName -Name $ZoneScopeName -PassThru

# Add IPs for default and EPA-Exclusion
Add-DnsServerResourceRecord -ZoneName $ZoneName -A -Name "@" -IPv4Address $PrivIP -PassThru
Add-DnsServerResourceRecord -ZoneName $ZoneName -A -Name "@" -IPv4Address $PubIP -ZoneScope $ZoneScopeName -PassThru

# Set Policy for the ZoneScope
Add-DnsServerQueryResolutionPolicy -Name $ZoneName -Action ALLOW -ClientSubnet "eq,$($Connectors)" -ZoneScope "$($ZoneScopeName),1" -ZoneName $ZoneName -PassThru