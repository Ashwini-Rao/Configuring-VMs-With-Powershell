$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

<# A generic function to configure static ip,
   rename the vm and get the vm into domain #>

function Configure_VM
{
    param ( [string]$name,
            [string]$ip,
            [string]$dnsIP,
            [string]$dom,
            [string]$gun,			
			[string]$gpwd )
                
    
    <#The Here-String construction provides an easy way for handling text, it's speciality is dealing with speech marks and other delimiters without the need for inserting escape characters.
      Place the first @", and especially the final, "@ on their own line. To be precise, the last thing on the first line must be @" "@ must be the first thing on the last line.#>
    # Splits the IP on period(.)
    $last_octet_gw = $ip.Split('.')

    # Changes the last octet to 250 and joins the IP to get the gateway address
    $last_octet_gw[-1] = 250
    $Global:gateway = $last_octet_gw -join '.'
    Write-Host "Setting IP of VM $name to $ip..."

    If ($name -imatch "Ubu*")
    {
        $EnableRoot = 'yes $gpwd | sudo -S passwd root
                       yes $gpwd | sudo -S passwd -u root'
        Invoke-VMScript -VM $name -GuestUser $gun -GuestPassword $gpwd -ScriptText $EnableRoot -ScriptType "Bash"
        Copy-VMGuestFile -Source "$ScriptDir\ubusetIP.sh" -Destination "/home/$gun" -LocalToGuest -VM $name -Force -GuestUser $gun -GuestPassword $gpwd 
        Start-Sleep -Seconds 30
        $execScript = 
        @"
            chmod 755 /home/$gun/ubusetIP.sh
            tr -d '\r' </home/$gun/ubusetIP.sh > /home/$gun/ubuntuIP.sh 
            chmod 755 /home/$gun/ubuntuIP.sh
            /home/$gun/ubuntuIP.sh  $ip $gateway $name
            rm -f /home/$gun/ubu*.sh
"@
        Invoke-VMScript -VM "$name" -ScriptText "$execScript" -ScriptType Bash -GuestUser $gun -GuestPassword $gpwd
        Start-Sleep -Seconds 15
        Get-VM $name | Restart-VM -Confirm:$false
    }
    ElseIf ($name -imatch "Suse*" -or $name -imatch "Sles*")
    {
        $EnableRoot = 'yes $gpwd | sudo -S passwd root
                       yes $gpwd | sudo -S passwd -u root'
        Invoke-VMScript -VM $name -GuestUser $gun -GuestPassword $gpwd -ScriptText $EnableRoot -ScriptType "Bash"
        Copy-VMGuestFile -Source "$ScriptDir\sles.sh" -Destination "/home/$gun" -LocalToGuest -VM $name -Force -GuestUser $gun -GuestPassword $gpwd
        Start-Sleep -Seconds 30
        $execScript = 
        @"
            chmod 755 /home/$gun/sles.sh
            tr -d '\r' </home/$gun/sles.sh > /home/$gun/slesIP.sh 
            chmod 755 /home/$gun/slesIP.sh
            /home/$gun/slesIP.sh $ip $gateway $name
            rm -f /home/$gun/sles*.sh
"@
        Invoke-VMScript -VM "$name" -ScriptText "$execScript" -ScriptType Bash -GuestUser $gun -GuestPassword $gpwd
        Start-Sleep -Seconds 15
        Get-VM $name | Restart-VM -Confirm:$false
    }
    ElseIf ($name -imatch "rhel*")
    {
        $EnableRoot = 'yes $gpwd | sudo -S passwd root
                       yes $gpwd | sudo -S passwd -u root'
        Invoke-VMScript -VM $name -GuestUser $gun -GuestPassword $gpwd -ScriptText $EnableRoot -ScriptType "Bash"
        Copy-VMGuestFile -Source "$ScriptDir\rhel.sh" -Destination "/home/$gun" -LocalToGuest -VM $name -Force -GuestUser $gun -GuestPassword $gpwd 
        $mac = (Get-NetworkAdapter -VM $name).MacAddress
        Start-Sleep -Seconds 30
        $execScript = 
        @"
            chmod 755 /home/$gun/rhel.sh
            tr -d '\r' </home/$gun/rhel.sh > /home/$gun/rhelIP.sh 
            chmod 755 /home/$gun/rhelIP.sh    
"@
        Invoke-VMScript -VM "$name" -ScriptText "$execScript" -ScriptType Bash -GuestUser $gun -GuestPassword $gpwd
        Invoke-VMScript -VM "$name" -ScriptText "/home/$gun/rhelIP.sh $ip $gateway $name $mac" -ScriptType Bash -GuestUser $gun -GuestPassword $gpwd
        Invoke-VMScript -VM "$name" -ScriptText "rm -f /home/$gun/rhel*.sh" -ScriptType Bash -GuestUser $gun -GuestPassword $gpwd
        Start-Sleep -Seconds 15
        Get-VM $name | Restart-VM -Confirm:$false
    }
    Else
    {
            # Set the IP configurations
            
            $winIP = '$Startip = "' + $ip + '" ;'
            $winIP += '$gw = "' + $gateway + '" ;'
            $winIP += '$adIP = "' + $dnsIP + '" ;'
            $winIP += '$wmi = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = true" ;'
            $winIP += '$wmi.EnableStatic("$Startip", "255.255.255.0") ;'
            $winIP += '$wmi.SetGateways("$gw", 1) ;'
            $winIP += '$wmi.SetDNSServerSearchOrder("$adIP") ;'

            Invoke-VMScript -VM "$name" -ScriptText "$winIP" -GuestUser $gun -GuestPassword $gpwd -ToolsWaitSecs 120
            $winIP_OP = Invoke-VMScript -VM "$name" -ScriptText "ipconfig" -GuestUser $gun -GuestPassword $gpwd -ToolsWaitSecs 60
            If ($winIP_OP.Contains($ip))
            {
                Write-Host "Setting IP address done..."
            }
            Else
            {
                Write-Host "Couldn't configure static IP..."
                break
            }
                        
            Write-Host "Renaming the VM to $name..."
            $rename = @"
                      Rename-Computer -ComputerName "$ip" -NewName "$name" -PassThru -Force
"@
            $compRename = Invoke-VMScript -VM "$name" -ScriptText "$rename" -GuestUser $gun -GuestPassword $gpwd -ToolsWaitSecs 120
            If ($compRename.Contains("True"))
            {
                 Get-VM $name | Restart-VM -Confirm:$false
                 Start-Sleep -Seconds 180
                 Write-Host "Rename successful" 
            }
            Else
            {
                 Write-Host "Unable to rename"
            }
                      
            Write-Host "Joining VM $name to domain..."
            $test = @"
                    Test-Connection -ComputerName $dnsIP -Quiet 
"@			
            $stat = Invoke-VMScript -VM "$name" -ScriptText "$test"  -GuestUser $gun -GuestPassword $gpwd -ToolsWaitSecs 120 
            If ($stat.Contains("True"))
            {	
                $domainFQDN = "$dom"
 
                $joinDomain = '$domain = "' + $domainFQDN + '" ; '
                $joinDomain += '$password = "$gpwd" | ConvertTo-SecureString -asPlainText -Force ;'
                $joinDomain += '$domain$gun = "$domain\EMadmin" ;'
                $joinDomain += '$credential = New-Object System.Management.Automation.PSCredential($domain$gun,$password) ;'
                $joinDomain += 'Add-Computer -DomainName $domain -Credential $credential -Force ;'

                Invoke-VMScript -VM "$name" -ScriptText "$joinDomain"  -GuestUser $gun -GuestPassword $gpwd -ToolsWaitSecs 120 
                Get-VM $name | Restart-VM -Confirm:$false
                Start-Sleep -Seconds 180
                $join = (Get-VM $name).Guest.HostName
                If ($join.Contains($dom))
                {
                    Write-Host "$name joined to domain successfully"
                }
                Else
                {
                    Write-Host "Unable to join domain"
                    break;
                }   
            }
            Else
            {
                Write-Host "Unable to contact AD.Could not join domain"
            }
                     
   	}
}