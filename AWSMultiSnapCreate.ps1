# AWSMultiSnapCreate - Generate snapshots for all the volumes of the servers in a list - AWS version
# Requires a valid AWS CLI credential and AWS tools for PowerShell - https://aws.amazon.com/powershell/
# USE WITH CAUTION - carefully check the server list prior to run this script
# Read the license before running it!
# https://github.com/hpalvarez/MultiSnapshotCreate
# Comentario de prueba

# If the -JustOS parameter is passed the script only does snaps of OS disks

param ([switch]$JustOS = $false)

# Loads server list from file ServerList.txt. Logs to AWSSnapLog.txt.

$servers = Get-Content -Path .\ServerList.txt

# Main loop

foreach ($server in $servers) {

    # Gets the instance ID from the "Name" tag. Filter out the NICs or other resources with the same name as the VM

    try { 
        $idInstanceFull = (Get-EC2Tag -Filter @{Name="tag:Name";Values="$server"}).ResourceId
        $idInstance = $idInstanceFull | Where-Object { $_ -clike "i-*" }
    } catch {
        Write-Warning ("[WARNING] Instance " + $server + " not found on this AWS account.")
    }
    
    # If not found, jumps to the next instance

    If (!$idInstance) {
        Write-Warning ("[WARNING] Instance " + $server + " not found on this AWS account.")
        Continue
    }

    # If found, proceed with the snapshots

    $volumes = @(Get-EC2Volume) | Where-Object { $_.Attachments.InstanceId -eq $idInstance} # Get the list of volumes of the instance
    $volumeIds = $volumes | ForEach-Object { $_.VolumeId} # Store the volume IDs on an array

    # Loop to generate each snapshot

    foreach ($volume in $volumeIds) {

        $device =  (Get-EC2Volume -VolumeId $volume).Attachments[0].Device # Gets the voulme attached device to add it into the snapshot name
        if ($device -eq "/dev/sda1") { $device = "sda1" } # If the device is sda1, remove the slashes and "dev"
        if ( ($device -ne "sda1") -and ($JustOS) ) { Continue } # Jumps to next disk if JustOS parameter is passed and disk is not sda1
        Write-Output ("[*] Starting snapshot of volume " + $volume + " - device " + $device + " from server " + $server)
        $snapName = "snap-" + $server + "-" + $device + "-$(Get-Date -Format MMddyy)" # Generates snapshot name with device id, server name and date
        
        # Generates the snapshot and hopefully catches errors
        
        try {
            $snapResult = New-EC2Snapshot -VolumeId $volume -Description $snapName
            Write-Output ("[*] Snapshot " + $snapResult.SnapshotId + " sucessfully created as " + $snapName)
            Add-Content .\AWSSnapLog.txt ("SUCCESS - Snapshot " + $snapResult.SnapshotId + " sucessfully created as " + $snapName)
        } catch {
            Write-Error ("[ERROR] Snapshot failed - check permissions, VM name or correct account")
            Add-Content .\AWSSnapLog.txt ("ERROR!! - Snapshot creation for volume " + $volume + " - device " + $device + " on server " + $server + " failed")
        }
    }

    Clear-Variable idInstance # Makes sure that the idInstance variable value is null before the next iteration
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
