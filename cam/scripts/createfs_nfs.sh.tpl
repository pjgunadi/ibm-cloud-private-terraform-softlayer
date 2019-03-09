#!/bin/bash
#Create Physical Volumes
pvcreate /dev/xvdc

#Create Volume Groups
vgcreate icp-vg /dev/xvdc

#Create Logical Volumes
lvcreate -L ${nfs_lv}G -n nfs-lv icp-vg

#Create Filesystems
mkfs.ext4 /dev/icp-vg/nfs-lv

#Create Directories
mkdir -p /export/icpshared

#Add mount in /etc/fstab
cat <<EOL | tee -a /etc/fstab
/dev/mapper/icp--vg-nfs--lv /export/icpshared ext4 defaults 0 0
EOL

#Mount Filesystems
mount -a

#Disable password authentication on public network
sed -i "s/^PasswordAuthentication yes$/PasswordAuthentication no/" /etc/ssh/sshd_config
cat <<EOL | tee -a /etc/ssh/sshd_config

Match Address 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
    PasswordAuthentication yes
EOL
systemctl restart sshd