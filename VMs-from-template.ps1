#To set the IP of the newly created vm

$setIP = 
{

# Increments the last octet by 1 and joins to get the next IP
$ip_split[-1] = [int]$ip_split[-1] + 1
If ($ip_split[-1] -ne 250 -and $ip_split[-1] -lt 255) {
    # Join the last octet to get next IP
    $start_ip = $ip_split -join '.'
}

# Set the IP configurations
New-NetIPAddress -InterfaceAlias Ethernet0 -IPAddress "$start_ip" -PrefixLength 24 -DefaultGateway "$gateway"
Set-DnsClientServerAddress -InterfaceAlias Ethernet0 -ServerAddresses ("$dns_ip")

}

<# A Generic Function to create VMs from Existing Tepmlates 
   Creates VMs in the specified ResourcePool, replaces the existing portgroup with the user specified portgroup.
   Calls a script to set the IP address of the VMs #>
function Create-VMs-Templates($name,$num,$template,$nic_port)
{
    New-ResourcePool -Name "$rp" -MemReservationGB 1
    For ($i=1; $i -le $num; $i++)
    {
         New-VM -Name "$name$i" -Template "$template" -ResourcePool "$rp" -Datastore CSA-NYS-DS1
         Get-VM -Name "$name$i" | Start-VM | Get-NetworkAdapter -Name "Network Adapter 1" | Set-NetworkAdapter -NetworkName "$nic_port" -StartConnected:$true -Confirm:$false
         Invoke-VMScript -VM "$name$i" -ScriptText "$setIP" -GuestUser Administrator -GuestPassword Unisys1234
         Echo "$name$i has been successfully created and configured."

    }
    Echo "Finished execution..."
}

# Prompts the user for environment specific information
$num_ems = Read-Host -Prompt 'Input the number of 2k12 ems to be created'

$name = Read-Host -Prompt 'Enter the name of your em(s)
'
$template = Get-Template -Name CSA-EMServer-W2K12-Aware 

$nic_port = Read-Host -Prompt 'Input the portgroup name to be assigned'

$dns_ip = Read-Host -Prompt 'Enter the starting IP that you want to use' 

# Splits the IP on period(.0
$ip_split = $dns_ip.Split('.')
$last_octet_gw = $dns_ip.Split('.')

# Changes the last octet to 250 and joins the IP to get the gateway address
$last_octet_gw[-1] = 250
$gateway = $last_octet_gw -join '.'

# Call to the function Create-VMs-Templates($name,$num,$template,$nic_port)
Create-VMs-Templates -name $name -num $num_ems -template $template -nic_port $nic_port
Echo "Intializing...."




