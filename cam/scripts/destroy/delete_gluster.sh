#!/bin/bash
NODEIP="$1"
HEKETI_PWD="$2"
removeGlusterNode() {
  NODEID=$(heketi-cli --user admin --secret "$HEKETI_PWD" topology info | grep "$NODEIP" -B5 | sed -e 's/^[[:space:]]*//' | awk -F: -v key="Node Id" '$1==key {print $2}' | tr -d [:space:])
  if [ -n "$NODEID" ]; then
    DEVICES=($(heketi-cli --user admin --secret "$HEKETI_PWD" node info $NODEID | sed '1,/Devices/d' | awk -F" " '{print $1}' | awk -F: '{print $2}'))
    heketi-cli --user admin --secret "$HEKETI_PWD" node disable $NODEID
    heketi-cli --user admin --secret "$HEKETI_PWD" node remove $NODEID
    for deviceid in "${DEVICES[@]}"; do
      heketi-cli --user admin --secret "$HEKETI_PWD" device delete "$deviceid"
    done
    heketi-cli --user admin --secret "$HEKETI_PWD" node delete $NODEID
    sudo gluster peer detach $NODEIP
  fi
}

if [ -n "$NODEIP" ]; then
  removeGlusterNode
fi
