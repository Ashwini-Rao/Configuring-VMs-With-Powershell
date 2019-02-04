$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

. "$ScriptDir\ConfigureVM.ps1" 

<# A Generic Function to create VMs from Existing Tepmlates 
   Creates VMs in the specified ResourcePool, replaces the existing portgroup with the user specified portgroup.
   Calls a script to set the IP address of the VMs and join them into domain #>

function Create-VMs-Templates
{
    param ( [string]$rp,
            [string]$vmname, 
            [string]$template, 
            [string]$nic_port,
            [string]$ip,
            [string]$dnsIP,
            [string]$domain,
	    [string]$Location,
	    [string]$datastore,
	    [string]$gun,
	    [string]$gpwd )

    #Create Resource Pool
    If (Get-ResourcePool $rp -ErrorAction SilentlyContinue)
    {
        Write-Host "$rp already exists..."
        $pool = $rp
    }
    Else
    {
        Write-Host "Creating resource pool $rp"
        $pool = New-ResourcePool -Name "$rp" -MemReservationGB 2 -Location $Location
        If ($pool)
        {
            Write-Host "$rp successfully created..."  
        }
        Else
        {
            Write-Host "Could not create $rp. Try again..."
            break
        }
            
    }
        
    If ($pool -or $pool.Name)
    {
        If (Get-ResourcePool $rp | Get-VM $vmname -ErrorAction SilentlyContinue)
        {
            Write-Host "$vmname already exists..."
            $vm = "$vmname"
        }
        Else
        {
            Write-Host "Creating vm $vmname"
            $vm = New-VM -Name "$vmname" -Template "$template" -ResourcePool "$rp" -Datastore $datastore 
            If ($vm)
            {
               Write-Host "$vmname successfully created from template..." 
            }
            Else
            {
                Write-Host "Could not create $vmname. Try again..."
                break
            }
        }
            
        If ($vm -or $vm.Name)
        {
              Write-Host "Assigning $nic_port"
              $adapter = Get-VM -Name "$vmname" | Start-VM | Get-NetworkAdapter -Name "Network Adapter 1" | Set-NetworkAdapter -NetworkName "$nic_port" -StartConnected:$true -Confirm:$false
              If ($adapter.NetworkName.Contains($nic_port))
              {
                    Write-Host "$nic_port has been successfully assigned..."  
              }
              Else
              {
                   Write-Host "$nic_port couldn't be assigned. Check if it is a valid portgroup and try again..."
                   break
              }
              Start-Sleep -Seconds 180
              Write-Host "Calling function to configure VMs"
              Configure_VM -name $vmname -ip $ip -dnsIP $dnsIP -dom $domain -gun $gun -gpwd $gpwd
              Write-Host "VMs have been successfully created,configured and added to domain..."
        }
        Else
        {
            Write-Host "Try again..."
            break
        }
    }
    Else
    {
        Write-Host "Try again..."
        break
    }
}
