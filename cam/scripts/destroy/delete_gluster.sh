#!/bin/bash
NODEIP="$1"
removeGlusterNode() {
  NODEID=$(heketi-cli topology info | grep "$NODEIP" -B5 | sed -e 's/^[[:space:]]*//' | awk -F: -v key="Node Id" '$1==key {print $2}' | tr -d [:space:])
  if [ -n "$NODEID" ]; then
    DEVICES=($(heketi-cli node info $NODEID | sed '1,/Devices/d' | awk -F" " '{print $1}' | awk -F: '{print $2}'))
    heketi-cli node disable $NODEID
    heketi-cli node remove $NODEID
    for deviceid in "${DEVICES[@]}"; do
      heketi-cli device delete "$deviceid"
    done
    heketi-cli node delete $NODEID
    sudo gluster peer detach $NODEIP
  fi
}

if [ -n "$NODEIP" ]; then
  removeGlusterNode
fi
