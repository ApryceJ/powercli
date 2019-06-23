#connect to vCenter
$viserver = Connect-VIServer -Server 10.220.111.11 -protocol https -Credential (Get-Credential)


#Creating HostAdptervsiwtch/nic

$vmhost = Get-VMHost

foreach ($s11host in $vmhost) {

$vmhostnic = Get-VMHostNetworkAdapter -VMHost $s11host | where Name -Like "vmnic0"

New-VirtualSwitch -Name vswitch1 -VMHost $s11host -Nic $vmhostnic

}



#forloop to create vmkernel storage port/network

$storage_IP = "10.11.0.1","10.11.0.2" 

$x = 0

foreach ($s11host in $vmhost) {

#Need to add if statement to check if vswitch exist. if exists need to use Set not New)

$s11switch = Get-VirtualSwitch -VMHost $s11host -Name vswitch1

New-VMHostNetworkAdapter -VMHost $s11host -PortGroup storage_portgroup -VirtualSwitch $s11switch -IP $storage_IP[$x] -SubnetMask 255.255.0.0

$x++ 

}
 

# Gets or verifies vmk1 ip address

    $change_vmk1 = Get-VMHostNetworkAdapter -VMHost vh2.s11.virt.nasp -VirtualSwitch vswitch1 -VMKernel vmk1

# Below sets or changes the IP of a Vswitch already created
    Get-VMHostNetworkAdapter -VMHost vh2.s11.virt.nasp | where {$_.PortGroupName -eq "storage_portgroup"} | Set-VMHostNetworkAdapter -IP 10.11.0.2 -SubnetMask 255.255.0.0 


#forloop for storage setup
$target = iqn.2016-07.nasp.virt.s11.store01:target0

foreach ($s11host in $vmhost) {
    
    #need if statement to check if softwareiscienabled true

#Get-VMHostStorage -VMHost $s11host | Set-VMHostStorage -SoftwareIScsiEnabled $true

$targetHba = Get-VMHostHba -VMHost $s11host -Type IScsi 

New-IScsiHbaTarget -IScsiHba $targetHba -Address 10.11.0.21 

}

#needed to have the iscsi connection show up
$VMhost | Get-VMHostStorage -RescanAllHba -RescanVmfs

#this runs once to create datastore on vCentre and not prehost

$hba = Get-VMhost | Get-VMHostHba -Type IScsi

$caname = Get-ScsiLun -Hba $hba 
    
New-Datastore -Server $viserver -Name iSCSI_SAN01 -Path $caname -Vmfs -FileSystemVersion 5

#this is used to verify datastore is created
get-datastore


#getting port groups and removing 

foreach ($s11host in $vmhost) {

$virtualSwitch = Get-VirtualSwitch -VMHost $s11host -Name vSwitch0
Get-VirtualPortGroup -VirtualSwitch $virtualSwitch -Name "*VM*" | Remove-VirtualPortGroup -Confirm $true

}

#creating new vswitch & portgroup for vm traffic

$vmhost = Get-VMHost

foreach ($s11host in $vmhost) {

#Need to add if statement to check if vswitch exist. if exists need to use Set not New)
    
$phNic = Get-VMHostNetworkAdapter -VMHost $s11host | Where {$_.DeviceName -Like "*2*"}
    
$vswitch = New-VirtualSwitch -VMHost $s11host -Name vswitch2 -Nic $phNic -

$s11switch = Get-VirtualSwitch -VMHost $s11host -Name vswitch2

New-VMHostNetworkAdapter -VMHost $s11host -PortGroup vm -VirtualSwitch $s11switch
}

$pgroup = Get-VirtualPortGroup -VMHost vh1.s11.virt.nasp -Name VM
#or get the value dynamically
$dstore = Get-Datastore
#$netname = get-networkname
$vmName = "www1.s11.virt.nasp"

#creating a VM
new-vm -Name $vmName -VMHost vh1.s11.virt.nasp -Portgroup $pgroup -Datastore $dstore -DiskGB 8 -MemoryGB 1
    
    # below will invoke a bash script to make changes to centos7 machine
    # Invoke-VMScript -VM $vmName -ScriptType Bash -ScriptText "C:\path\to\bash\script" -HostCredential (Get-Credential)

#create OScustomization spec
New-OSCustomizationSpec -Server $viserver -Name "CentOS7 WWW Spec" -TimeZone Vancouver -OSType Linux -NamingScheme Fixed -NamingPrefix www 

New-OSCustomizationNicMapping -OSCustomizationSpec "CentOS7 WWW Spec" -SubnetMask 255.255.255.0 -DefaultGateway 10.220.125.254 -Dns 142.232.221.253

#creating a template
new-template -VM $vmNmae -VMHost vh2.s11.virt.nasp -Datastore $dstore


#Migrate the VM's

#create a HA cluster

#FaultTolerance for VM