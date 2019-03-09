#!/bin/bash
#Create Physical Volumes
pvcreate /dev/xvdc

#Create Volume Groups
vgcreate icp-vg /dev/xvdc

#Create Logical Volumes
lvcreate -L ${kubelet_lv}G -n kubelet-lv icp-vg
lvcreate -L ${etcd_lv}G -n etcd-lv icp-vg
#lvcreate -L ${registry_lv}G -n registry-lv icp-vg
lvcreate -L ${docker_lv}G -n docker-lv icp-vg
lvcreate -L ${management_lv}G -n management-lv icp-vg

#Create Filesystems
mkfs.ext4 /dev/icp-vg/kubelet-lv
mkfs.ext4 /dev/icp-vg/docker-lv
mkfs.ext4 /dev/icp-vg/etcd-lv
#mkfs.ext4 /dev/icp-vg/registry-lv
mkfs.ext4 /dev/icp-vg/management-lv

#Create Directories
mkdir -p /var/lib/docker
mkdir -p /var/lib/kubelet
mkdir -p /var/lib/etcd
mkdir -p /var/lib/registry
mkdir -p /var/lib/icp

#Add mount in /etc/fstab
cat <<EOL | tee -a /etc/fstab
/dev/mapper/icp--vg-kubelet--lv /var/lib/kubelet ext4 defaults 0 0
/dev/mapper/icp--vg-docker--lv /var/lib/docker ext4 defaults 0 0
/dev/mapper/icp--vg-etcd--lv /var/lib/etcd ext4 defaults 0 0
/dev/mapper/icp--vg-management--lv /var/lib/icp ext4 defaults 0 0
EOL

#Mount Registry for Single Master
if [ ${flag_usenfs} -eq 0 ]; then
  lvcreate -L ${registry_lv}G -n registry-lv icp-vg
  mkfs.ext4 /dev/icp-vg/registry-lv
  cat <<EOR | tee -a /etc/fstab
/dev/mapper/icp--vg-registry--lv /var/lib/registry ext4 defaults 0 0
EOR

fi

#Mount Filesystems
mount -a

#Disable password authentication on public network
sed -i "s/^PasswordAuthentication yes$/PasswordAuthentication no/" /etc/ssh/sshd_config
cat <<EOL | tee -a /etc/ssh/sshd_config

Match Address 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
    PasswordAuthentication yes
EOL
systemctl restart sshd