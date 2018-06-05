# PowerShell_WorkEnvironment

To automate work environment, so that more time is spent on testing the feature rather than setting up the environment.
This script creates multiple VMs of different OS versions from existing templates in vSphere Web CLient.
It then configures the basic configurations and deploys the product. Now, you are all set to test feature(s).

To use these scripts:
1. Download and Install Windows PowerShell ISE.
2. Run in Administrator mode.
3. Import the following modules :
    Import-Module VMware.VimAutomation.Core
    Import-Module VMware.VimAutomation.Vds
    Import-Module VMware.VimAutomation.Storage
4. Save these scripts locally, either click on Run or enter ./script-name.ps1 from CLI.
   
