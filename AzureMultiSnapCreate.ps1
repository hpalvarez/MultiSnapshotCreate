# AzureMultiSnapCreate - Generate snapshots for all the volumes of the servers in a list - Azure version
# Requires Azure tools for PowerShell - https://docs.microsoft.com/en-us/powershell/azure/
# USE WITH CAUTION - carefully check the server list prior to run this script
# Read the license before running it!
# https://github.com/hpalvarez/MultiSnapshotCreate


# Loads server list. Format is name;resource group;location
# Logs to AzureSnapLog.txt

$header = "name","rg","location"
$servers = Import-Csv -Delimiter ";" -Header $header -Path .\ServerList.txt

# Main loop

foreach ($server in $servers)
{
    # Check if VM exists and gets all VM info

    Write-Output ("[*] Starting snapshot creation for server " + $server.name)
    $serverData = Get-AzVM -ResourceGroupName $server.rg -Name $server.name
    if (!$serverData) {
        Write-Error ("Server " + $server.name + " not found, check VM name, resource group name, location or subscription")
        Continue
    }

    # OS disk snapshot creation

    Write-Output ("[*] Creating OS disk snapshot for server " + $server.name)
    $snapshotDisk = $serverData.StorageProfile # Gets all disks of VM
    $OSDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $snapshotDisk.OsDisk.ManagedDisk.id -CreateOption Copy -Location $server.location -OsType Windows # Configures the snapshot
    $snapshotNameOS = "$($server.name)_$($snapshotdisk.OsDisk.Name)_snapshot_osdisk_$(Get-Date -Format MMddyy)" # Prepares the OS disk snapshot name

    # Tries to do the snapshot, if it fails shows an error, in both cases it logs to AzureSnapLog.txt
    
    try {
        New-AzSnapshot -ResourceGroupName $server.rg -SnapshotName $snapshotNameOS -Snapshot $OSDiskSnapshotConfig -ErrorAction Stop
        Add-Content -Path .\AzureSnapLog.txt ("Success;" + $snapshotNameOS + ";" + $server.name + ";" + $server.rg + ";" + $server.location)
    } catch {
        Write-Error ("OS disk snapshot for " + $server.name + " failed")
        Add-Content -Path .\AzureSnapLog.txt ("ERROR!!;" + $snapshotNameOS + ";" + $server.name + ";" + $server.rg + ";" + $server.location)
    }

    # Data disk snapshot creation

    $dataDisks = ($snapshotDisk.DataDisks).name # Gets all the data disks

    # Loop to create each data disk snapshot

    foreach ($dataDisk in $dataDisks) {

        $dataDisk = Get-AzDisk -ResourceGroupName $serverData.rg -DiskName $dataDisk # Get data disk information
        Write-Output ("[*] Creating data disk " + $dataDisk.name + " snapshot for server " + $server.name)
        $DataDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $dataDisk.Id -CreateOption Copy -Location $server.location # Configures the snapshot
        $snapshotNameData = "$($server.name)_$($dataDisk.name)_snapshot_datadisk_$(Get-Date -Format MMddyy)" # Prepares the snapshot name
        
        # Tries to do the snapshot, if it fails shows an error, in both cases it logs to AzureSnapLog.txt
        
        try {
            New-AzSnapshot -ResourceGroupName $server.rg -SnapshotName $snapshotNameData -Snapshot $DataDiskSnapshotConfig -ErrorAction Stop
            Add-Content -Path .\AzureSnapLog.txt ("Success;" + $snapshotNameData + ";" + $server.name + ";" + $server.rg + ";" + $server.location)
        } catch {
            Write-Error ("Data disk snapshot for " + $server.name + " - disk " + $dataDisk.name + " failed")
            Add-Content -Path .\AzureSnapLog.txt ("ERROR!!;" + $snapshotNameData + ";" + $server.name + ";" + $server.rg + ";" + $server.location)
        }
    }
    Clear-Variable serverData # Clears variables
}

<# MIT License

Copyright (c) 2020 Hernán Álvarez

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. #>
