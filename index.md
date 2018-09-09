
# Context
Here is a simple script to create multiple VMs of different OS versions from existing templates in the vSphere Web CLient. 
It also configures the basic configurations and deploys it.

# Instructions
* Download and Install Windows PowerShell ISE from https://www.microsoft.com/en-in/download/details.aspx?id=40855. Follow the instructions   to install Windows PowerShell ISE.
* Search for Windows PowerShell ISE and then run it in Administrator mode.
* To import the following modules into Powershell, enter: 
    * Import-Module VMware.VimAutomation.Core 
    * Import-Module VMware.VimAutomation.Vds 
    * Import-Module VMware.VimAutomation.Storage
* Save the scripts in "scripts" folder locally in your system. 
* Open "auto.ini" file from Powershell and edit to fill the configuration details necessary to spin up the VM(s). Save the file.
* Open "cfgread.ps1" file from Powershell and click on Run or directly run the script from CLI as "./cfgread.ps1".
* Execution starts and progress can be seen on the output window.
* Once the execution is completed, to verify the VM(s) are created either 
      * Run the following command : **Get-ResourcePool -Name <resouce-pool name> | Get-VM** or
      * Login to your vSphere Web Client and verify the VM(s) are created in the Resource Pool you specified. 
* Open the VM(s) either manually or through Powershell : Get-ResourcePool -Name <resouce-pool name> | Get-VM | Open-VMConsoleWindow to       verify that the specified configuration details are done.
 
     
      

