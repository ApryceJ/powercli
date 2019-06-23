#! /bin/bash

hostnamectl set-hostname www1.s11.virt.nasp
#hostnamectl set-hostname www2.s11.virt.nasp
#hostnamectl set-hostname www3.s11.virt.nasp
#hostnamectl set-hostname www4.s11.virt.nasp

systemctl disable firewalld
systemctl stop firewalld
systemctl disable iptables

setenforce 0
sed -r -i 's/SELINUX+(enforcing|disabled)/SELINUX+disabled/' /etc/selinux/config

yum -y install epel-release
yum -y install stress
yum -y update