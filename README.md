# MultiSnapshotCreate

PowerShell scripts to create snapsots of all the disks of a AWS EC2 or Azure VM.

These scripts grab a list of Amazon AWS EC2 instances or Azure VMs from the file ServerList.txt (that you must create in the same folder of the script) and then creates a snapshot of each disk of it.

It requires to have the Azure or AWS Powershell tools correctly installed and configured.

Be careful to use them! Snapshot creation could cause increased storage costs on your account. The scripts are provided just to help other sysadmins that may need something like it without any kind of warranty.
