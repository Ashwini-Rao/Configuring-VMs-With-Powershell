#Picks up the execution path of the current script and uses the same path to run the other scripts
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

#Reads input from the auto.ini file
$autocfg = Get-Content $ScriptDir\auto.ini

$serverIP = $autocfg[0].split("=")[1]
$RP = $autocfg[1].split("=")[1]
$Location = $autocfg[2].split("=")[1]
$datastore = $autocfg[3].split("=")[1]
$osType = $autocfg[4].split("=")[1]
$template = $autocfg[5].split("=")[1]
$gun = $autocfg[6].split("=")[1]
$gpwd = $autocfg[7].split("=")[1]
$VMnum = $autocfg[8].split("=")[1]
$PortGroup = $autocfg[9].split("=")[1]
$Global:StartingIP = $autocfg[10].split("=")[1]
$dnsIP = $autocfg[11].split("=")[1]
$domain = $autocfg[12].split("=")[1]
$prefix = $autocfg[13].split("=")[1]

# User will be prompted to enter vsphere Web Client credentials
$cred = Get-Credential
Connect-VIServer -Server $serverIP -Credential $cred


#Calls the other script
. "$ScriptDir\CreateVMs.ps1"

Write-Host "Calling function to create $osType"
For ($i = 1; $i -le $VMnum; $i++)
{
    $ip_split = $StartingIP.Split('.')
    # Increments the last octet by 1 and joins to get the next IP  
    $ip_split[-1] = [int]$ip_split[-1] + 1
    If ([int]$ip_split[-1] -ne 250 -and [int]$ip_split[-1] -lt 255) 
    {
            # Join the last octet to get next IP
            $Global:StartingIP = $ip_split -join '.'
    }
    Else
    {
            Write-Error "Not a valid IP address. Specify a different subnet"
    }
    $name = "$osType-"+$i
    $vmname = "$prefix-$name"
    Create-VMs-Templates -rp $RP -vmname $vmname -template $template -nic_port $PortGroup -ip $StartingIP -dnsIP $dnsIP -domain $domain -location $Location -datastore $datastore -gun $gun -gpwd $gpwd
    Start-Sleep -Seconds 30
}