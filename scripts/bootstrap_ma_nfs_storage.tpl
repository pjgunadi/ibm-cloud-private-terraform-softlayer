#!/bin/bash

SHARE_ATTRIBUTES="(rw,sync,insecure,no_root_squash,no_subtree_check,nohide)"

sudo mkdir -p /export/icpshared

if [ ${flag_ma_nfs} -eq 1 ]; then
    # Start NFS server
    sudo systemctl enable nfs-server
    sudo systemctl start nfs-server

    sudo mkdir -p /export/icpshared/var/lib/registry
    sudo mkdir -p /export/icpshared/var/lib/icp/audit
    sudo mkdir -p /export/icpshared/var/log/audit

    cat <<EOF | sudo tee -a /etc/exports
/export/icpshared/var/lib/registry *$SHARE_ATTRIBUTES
/export/icpshared/var/lib/icp/audit *$SHARE_ATTRIBUTES
/export/icpshared/var/log/audit *$SHARE_ATTRIBUTES
EOF
    sudo /usr/sbin/exportfs -ra
fi