#!/bin/bash

VA_NODES="${va_ips}"
TARGET_PATH=${mount_path}
NODEGROUP_NAME="icpva"
SHARE_ATTRIBUTES="(rw,sync,insecure,no_root_squash,no_subtree_check,nohide)"

#Create Netgroup
VA_GROUP=$NODEGROUP_NAME
for node in $VA_NODES; do
    GRP_MEMBER="($node,,)"
    VA_GROUP=$(echo $VA_GROUP $GRP_MEMBER)
done
if [ -f /etc/netgroup ]; then
  sudo sed -i /^"$NODEGROUP_NAME".*$/d /etc/netgroup
fi
echo "$VA_GROUP" | sudo tee -a /etc/netgroup

if [ ${flag_va_nfs} -eq 1 ]; then
    [ -d /export/icpshared$TARGET_PATH ] || sudo mkdir -p /export/icpshared$TARGET_PATH
    NFSCLIENT=""
    for node in $VA_NODES; do
        NFSCLIENT=$(echo $NFSCLIENT $node$SHARE_ATTRIBUTES)
    done
    SEARCH_PATTERN=$(echo $TARGET_PATH | sed 's/\//\\\//g')
    sed -i "/^\/export\/icpshared$SEARCH_PATTERN/d" /etc/exports

    cat <<EOF | sudo tee -a /etc/exports
/export/icpshared$TARGET_PATH $NFSCLIENT
EOF
    sudo /usr/sbin/exportfs -ra
fi