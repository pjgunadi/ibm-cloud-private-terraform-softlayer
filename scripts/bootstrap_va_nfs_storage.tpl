#!/bin/bash

TARGET_PATH=${mount_path}
SHARE_ATTRIBUTES="(rw,sync,insecure,no_root_squash,no_subtree_check,nohide)"

sudo mkdir -p /export/icpshared

if [ ${flag_va_nfs} -eq 1 ]; then
    # Start NFS server
    sudo systemctl enable nfs-server
    sudo systemctl start nfs-server

    mkdir -p /export/icpshared$TARGET_PATH
    cat <<EOF | sudo tee -a /etc/exports
/export/icpshared$TARGET_PATH *$SHARE_ATTRIBUTES
EOF
    sudo /usr/sbin/exportfs -ra
fi