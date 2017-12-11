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
#lvcreate -l 100%FREE -n management-lv icp-vg

#Create Filesystems
mkfs.ext4 /dev/icp-vg/kubelet-lv
mkfs.ext4 /dev/icp-vg/docker-lv
mkfs.ext4 /dev/icp-vg/etcd-lv
mkfs.ext4 /dev/icp-vg/registry-lv
#mkfs.ext4 /dev/icp-vg/management-lv

#Create Directories
mkdir -p /var/lib/docker
mkdir -p /var/lib/kubelet
mkdir -p /var/lib/etcd
mkdir -p /var/lib/registry
#mkdir -p /opt/ibm/cfc

#Add mount in /etc/fstab
cat <<EOL | tee -a /etc/fstab
/dev/mapper/icp--vg-kubelet--lv /var/lib/kubelet ext4 defaults 0 0
/dev/mapper/icp--vg-docker--lv /var/lib/docker ext4 defaults 0 0
/dev/mapper/icp--vg-etcd--lv /var/lib/etcd ext4 defaults 0 0
/dev/mapper/icp--vg-registry--lv /var/lib/registry ext4 defaults 0 0
#/dev/mapper/icp--vg-management--lv /opt/ibm/cfc ext4 defaults 0 0
EOL

#Mount Filesystems
mount -a