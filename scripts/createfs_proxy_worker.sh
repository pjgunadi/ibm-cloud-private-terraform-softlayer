#!/bin/bash
#Create Physical Volumes
pvcreate /dev/xvdc

#Create Volume Groups
vgcreate icp-vg /dev/xvdc

#Create Logical Volumes
lvcreate -L 10G -n kubelet-lv icp-vg
lvcreate -L 40G -n docker-lv icp-vg

#Create Filesystems
mkfs.ext4 /dev/docker-vg/kubelet-lv
mkfs.ext4 /dev/docker-vg/docker-lv

#Create Directories
mkdir -p /var/lib/docker
mkdir -p /var/lib/kubelet

#Add mount in /etc/fstab
cat <<EOL | tee -a /etc/fstab
/dev/mapper/docker--vg-kubelet--lv /var/lib/kubelet ext4 defaults 0 0
/dev/mapper/docker--vg-docker--lv /var/lib/docker ext4 defaults 0 0
EOL

#Mount Filesystems
mount -a