#!/bin/bash

TARGET_PATH=${mount_path}
BACKUP_PATH=$TARGET_PATH.$(date +%F)
CHK_NFS_MOUNT=$(nfsstat -m | grep $TARGET_PATH)

if [ ${flag_va_nfs} -eq 1 -a "$TARGET_PATH" != "" -a "$CHK_NFS_MOUNT" != "" ]; then
  [ ! -d $TARGET_PATH ] && mkdir -p $TARGET_PATH
  DIR_SIZE=$(ls $TARGET_PATH | wc -w)
  if [ $DIR_SIZE -gt 0 ]; then
    sudo mv $TARGET_PATH $BACKUP_PATH
    sudo mkdir -p $TARGET_PATH
  fi
  cat <<EOF | sudo tee -a /etc/fstab
${nfs_ip}:/export/icpshared$TARGET_PATH   $TARGET_PATH    nfs4    auto,nofail,noatime,nolock,intr,tcp,actimeo=1800,rw 0 0
EOF
  sudo mount -a
  echo "NFS Mounted"
  if [ -d $BACKUP_PATH ]; then
    sudo mv $BACKUP_PATH/* $TARGET_PATH
    [ $(ls $BACKUP_PATH | wc -w) -eq 0 ] && rmdir $BACKUP_PATH
    echo "Moved existing files to NFS"
  fi
else
  echo "Skipped mounting NFS"
fi

exit 0
