#connect to vCenter
$viserver = Connect-VIServer -Server 10.220.111.11 -protocol https -Credential (Get-Credential)

#Variables

$vmhost = Get-VMHost

$storage_IP = "10.11.0.1","10.11.0.2" 

$x = 0

foreach ($s11host in $vmhost) {

#Creating HostAdptervsiwtch/nic

$vmhostnic = Get-VMHostNetworkAdapter -VMHost $s11host | where Name -Like "vmnic0"

New-VirtualSwitch -Name vswitch1 -VMHost $s11host -Nic $vmhostnic


#create vmkernel storage port/network

#Need to add if statement to check if vswitch exist. if exists need to use Set not New)

$s11switch = Get-VirtualSwitch -VMHost $s11host -Name vswitch1

New-VMHostNetworkAdapter -VMHost $s11host -PortGroup storage_portgroup -VirtualSwitch $s11switch -IP $storage_IP[$x] -SubnetMask 255.255.0.0

$x++ 

print "Setting up vmkernel for storage"
# Gets or verifies vmk1 ip address
    $change_vmk1 = Get-VMHostNetworkAdapter -VMHost vh2.s11.virt.nasp -VirtualSwitch vswitch1 -VMKernel vmk1

# Below sets or changes the IP of a Vswitch already created
    Get-VMHostNetworkAdapter -VMHost vh2.s11.virt.nasp | where {$_.PortGroupName -eq "storage_portgroup"} | Set-VMHostNetworkAdapter -IP 10.11.0.2 -SubnetMask 255.255.0.0 

#storage setup
$target = iqn.2016-07.nasp.virt.s11.store01:target0

    #need if statement to check if softwareiscienabled true
    #Get-VMHostStorage -VMHost $s11host | Set-VMHostStorage -SoftwareIScsiEnabled $true

$targetHba = Get-VMHostHba -VMHost $s11host -Type IScsi 

New-IScsiHbaTarget -IScsiHba $targetHba -Address 10.11.0.21 


}

# These are one off commands to be run at VIserver

#needed to have the iscsi connection show up, refresh storage
$VMhost | Get-VMHostStorage -RescanAllHba -RescanVmfs

#this runs once to create datastore on vCentre and not prehost
$hba = Get-VMhost | Get-VMHostHba -Type IScsi

$caname = Get-ScsiLun -Hba $hba 
    
New-Datastore -Server $viserver -Name iSCSI_SAN01 -Path $caname -Vmfs -FileSystemVersion 5

#this is used to verify datastore is created
print " Verifiying the storage"
get-datastore

#Next will be adding a VM... to be continued