$uservSphereCredentials = Get-Credential

Connect-VIServer -Server 192.63.246.79 -User $uservSphereCredentials.UserName -Password $uservSphereCredentials.GetNetworkCredential().Password -Protocol https