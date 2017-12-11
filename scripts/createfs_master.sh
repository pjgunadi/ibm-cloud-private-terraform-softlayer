#!/bin/bash
#Create Physical Volumes
pvcreate /dev/xvdc

#Create Volume Groups
vgcreate icp-vg /dev/xvdc

#Create Logical Volumes
lvcreate -L 10G -n kubelet-lv icp-vg
lvcreate -L 40G -n docker-lv icp-vg
lvcreate -L 2G -n etcd-lv icp-vg
lvcreate -L 10G -n registry-lv icp-vg
#lvcreate -l 100%FREE -n management-lv data-vg

#Create Filesystems
mkfs.ext4 /dev/docker-vg/kubelet-lv
mkfs.ext4 /dev/docker-vg/docker-lv
mkfs.ext4 /dev/data-vg/etcd-lv
mkfs.ext4 /dev/data-vg/registry-lv
#mkfs.ext4 /dev/data-vg/management-lv

#Create Directories
mkdir -p /var/lib/docker
mkdir -p /var/lib/kubelet
mkdir -p /var/lib/etcd
mkdir -p /var/lib/registry
#mkdir -p /opt/ibm/cfc

#Add mount in /etc/fstab
cat <<EOL | tee -a /etc/fstab
/dev/mapper/docker--vg-kubelet--lv /var/lib/kubelet ext4 defaults 0 0
/dev/mapper/docker--vg-docker--lv /var/lib/docker ext4 defaults 0 0
/dev/mapper/data--vg-etcd--lv /var/lib/etcd ext4 defaults 0 0
/dev/mapper/data--vg-registry--lv /var/lib/registry ext4 defaults 0 0
#/dev/mapper/data--vg-management--lv /opt/ibm/cfc ext4 defaults 0 0
EOL

#Mount Filesystems
mount -a