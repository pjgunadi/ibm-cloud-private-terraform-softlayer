#!/bin/bash
if [ ${flag_ma_nfs} -eq 1 ]; then
  sudo mkdir -p /var/lib/registry
  sudo mkdir -p /var/lib/icp/audit
  sudo mkdir -p /var/log/audit

  cat <<EOF | sudo tee -a /etc/fstab
${nfs_ip}:/export/icpshared/var/lib/registry   /var/lib/registry    nfs4    auto,nofail,noatime,nolock,intr,tcp,actimeo=1800,rw 0 0
${nfs_ip}:/export/icpshared/var/lib/icp/audit /var/lib/icp/audit    nfs4    auto,nofail,noatime,nolock,intr,tcp,actimeo=1800,rw 0 0
${nfs_ip}:/export/icpshared/var/log/audit    /var/log/audit    nfs4    auto,nofail,noatime,nolock,intr,tcp,actimeo=1800,rw 0 0
EOF

  sudo mount -a
  echo "NFS Mounted"
else
  echo "Skipped mounting NFS"
fi

exit 0
