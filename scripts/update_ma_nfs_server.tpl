#!/bin/bash

MASTER_NODES="${master_ips}"
NODEGROUP_NAME="icpmaster"
SHARE_ATTRIBUTES="(rw,sync,insecure,no_root_squash,no_subtree_check,nohide)"

#Create Netgroup
MASTER_GROUP=$NODEGROUP_NAME
for node in $MASTER_NODES; do
    GRP_MEMBER="($node,,)"
    MASTER_GROUP=$(echo $MASTER_GROUP $GRP_MEMBER)
done
if [ -f /etc/netgroup ]; then
  sudo sed -i /^"$NODEGROUP_NAME".*$/d /etc/netgroup
fi
echo "$MASTER_GROUP" | sudo tee -a /etc/netgroup

if [ ${flag_ma_nfs} -eq 1 ]; then
    [ -d /export/icpshared/var/lib/registry ] || sudo mkdir -p /export/icpshared/var/lib/registry
    [ -d /export/icpshared/var/lib/icp/audit ] || sudo mkdir -p /export/icpshared/var/lib/icp/audit
    [ -d /export/icpshared/var/log/audit ] || sudo mkdir -p /export/icpshared/var/log/audit

    NFSCLIENT=""
    for node in $MASTER_NODES; do
        NFSCLIENT=$(echo $NFSCLIENT $node$SHARE_ATTRIBUTES)
    done

    sed -i "/^\/export\/icpshared\/var\/lib\/registry/d" /etc/exports
    sed -i "/^\/export\/icpshared\/var\/lib\/icp\/audit/d" /etc/exports
    sed -i "/^\/export\/icpshared\/var\/log\/audit/d" /etc/exports

    cat <<EOF | sudo tee -a /etc/exports
/export/icpshared/var/lib/registry $NFSCLIENT
/export/icpshared/var/lib/icp/audit $NFSCLIENT
/export/icpshared/var/log/audit $NFSCLIENT
EOF
    sudo /usr/sbin/exportfs -ra
fi