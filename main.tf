provider "ibm" {
  bluemix_api_key    = "${var.ibm_bmx_api_key}"
  softlayer_username = "${var.ibm_sl_username}"
  softlayer_api_key  = "${var.ibm_sl_api_key}"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"

  provisioner "local-exec" {
    command = "cat > ${var.ssh_key_name} <<EOL\n${tls_private_key.ssh.private_key_pem}\nEOL"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${var.ssh_key_name}"
  }
}

resource "ibm_compute_ssh_key" "ibm_public_key" {
  label      = "${var.ssh_key_name}"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

#Security Groups
# #Private Outbound
# resource "ibm_security_group" "private_outbound" {
#     name = "${lower(var.instance_prefix)}-private-outbound"
#     description = "allow outbound private network"
# }
# resource "ibm_security_group_rule" "allow_outbound" {
#     direction = "egress"
#     ether_type = "IPv4"
#     security_group_id = "${ibm_security_group.private_outbound.id}"
# }
# #Private Inbound
# resource "ibm_security_group" "private_inbound" {
#     name = "${lower(var.instance_prefix)}-private-inbound"
#     description = "allow inbound private network"
# }
# resource "ibm_security_group_rule" "allow_inbound" {
#     direction = "ingress"
#     ether_type = "IPv4"
#     remote_group_id = "${ibm_security_group.private_outbound.id}"
#     security_group_id = "${ibm_security_group.private_inbound.id}"
# }
# #Public Outbound
# resource "ibm_security_group" "public_outbound" {
#     name = "${lower(var.instance_prefix)}-public-outbound"
#     description = "allow outbound public network"
# }
# resource "ibm_security_group_rule" "public_outbound" {
#     direction = "egress"
#     ether_type = "IPv4"
#     security_group_id = "${ibm_security_group.public_outbound.id}"
# }
# #Public SSH
# resource "ibm_security_group" "public_inbound_ssh" {
#     name = "${lower(var.instance_prefix)}-public-inbound-ssh"
#     description = "allow inbound ssh"
# }
# resource "ibm_security_group_rule" "public_inbound_ssh" {
#     direction      = "ingress"
#     ether_type     = "IPv4"
#     port_range_min = 22
#     port_range_max = 22
#     protocol       = "tcp"
#     security_group_id = "${ibm_security_group.public_inbound_ssh.id}"
# }
# #Public Master
# resource "ibm_security_group" "public_inbound_master" {
#     name = "${lower(var.instance_prefix)}-public-inbound-master"
#     description = "allow inbound master node"
# }
# resource "ibm_security_group_rule" "public_inbound_master_8443" {
#     direction      = "ingress"
#     ether_type     = "IPv4"
#     port_range_min = 8443
#     port_range_max = 8443
#     protocol       = "tcp"
#     security_group_id = "${ibm_security_group.public_inbound_master.id}"
# }
# resource "ibm_security_group_rule" "public_inbound_master_9443" {
#     direction      = "ingress"
#     ether_type     = "IPv4"
#     port_range_min = 9443
#     port_range_max = 9443
#     protocol       = "tcp"
#     #remote_group_id = "${ibm_security_group.public_outbound.id}"
#     security_group_id = "${ibm_security_group.public_inbound_master.id}"
# }
# resource "ibm_security_group_rule" "public_inbound_master_8001" {
#     direction      = "ingress"
#     ether_type     = "IPv4"
#     port_range_min = 8001
#     port_range_max = 8001
#     protocol       = "tcp"
#     security_group_id = "${ibm_security_group.public_inbound_master.id}"
# }
# resource "ibm_security_group_rule" "public_inbound_master_8500" {
#     direction      = "ingress"
#     ether_type     = "IPv4"
#     port_range_min = 8500
#     port_range_max = 8500
#     protocol       = "tcp"
#     security_group_id = "${ibm_security_group.public_inbound_master.id}"
# }
# resource "ibm_security_group_rule" "public_inbound_master_4300" {
#     direction      = "ingress"
#     ether_type     = "IPv4"
#     port_range_min = 4300
#     port_range_max = 4300
#     protocol       = "tcp"
#     remote_ip = "${ibm_compute_vm_instance.management.0.ipv4_address}"
#     security_group_id = "${ibm_security_group.public_inbound_master.id}"
# }
# #Public Proxy
# resource "ibm_security_group" "public_inbound_proxy" {
#     name = "${lower(var.instance_prefix)}-public-inbound-proxy"
#     description = "allow inbound proxy"
# }
# resource "ibm_security_group_rule" "public_inbound_proxy" {
#     direction      = "ingress"
#     ether_type     = "IPv4"
#     port_range_min = 30000
#     port_range_max = 32767
#     protocol       = "tcp"
#     security_group_id = "${ibm_security_group.public_inbound_proxy.id}"
# }
#Local variables
locals {
  master_datadisk     = "${var.master["kubelet_lv"] + var.master["docker_lv"] + var.master["registry_lv"] + var.master["etcd_lv"] + var.master["management_lv"] + 1}"
  proxy_datadisk      = "${var.proxy["kubelet_lv"] + var.proxy["docker_lv"] + 1}"
  management_datadisk = "${var.management["kubelet_lv"] + var.management["docker_lv"] + var.management["management_lv"] + 1}"
  va_datadisk = "${var.va["kubelet_lv"] + var.va["docker_lv"] + var.va["va_lv"] + 1}"
  worker_datadisk     = "${var.worker["kubelet_lv"] + var.worker["docker_lv"] + 1}"
  nfs_datadisk     = "${var.nfs["nfs_lv"] + 1}"
  flag_usenfs = "${var.master["nodes"] > 1 && var.nfs["nodes"] >= 1 ? 1 : 0}"

  #Destroy nodes variables
  icp_boot_node_ip = "${ibm_compute_vm_instance.boot.0.ipv4_address}"
  heketi_ip        = "${var.gluster["nodes"] > 0 ? element(split(",", join(",", ibm_compute_vm_instance.gluster.*.ipv4_address)), 0) : ""}"
  heketi_svc_ip    = "${var.gluster["nodes"] > 0 ? element(split(",", join(",", ibm_compute_vm_instance.gluster.*.ipv4_address_private)), 0) : ""}"
  ssh_options      = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
}

data "template_file" "createfs_master" {
  template = "${file("${path.module}/scripts/createfs_master.sh.tpl")}"

  vars {
    kubelet_lv    = "${var.master["kubelet_lv"]}"
    docker_lv     = "${var.master["docker_lv"]}"
    etcd_lv       = "${var.master["etcd_lv"]}"
    registry_lv   = "${var.master["registry_lv"]}"
    management_lv = "${var.master["management_lv"]}"
    flag_usenfs   = "${local.flag_usenfs}"
  }
}

data "template_file" "createfs_proxy" {
  template = "${file("${path.module}/scripts/createfs_proxy.sh.tpl")}"

  vars {
    kubelet_lv = "${var.proxy["kubelet_lv"]}"
    docker_lv  = "${var.proxy["docker_lv"]}"
  }
}

data "template_file" "createfs_management" {
  template = "${file("${path.module}/scripts/createfs_management.sh.tpl")}"

  vars {
    kubelet_lv    = "${var.management["kubelet_lv"]}"
    docker_lv     = "${var.management["docker_lv"]}"
    management_lv = "${var.management["management_lv"]}"
  }
}

data "template_file" "createfs_va" {
  template = "${file("${path.module}/scripts/createfs_va.sh.tpl")}"

  vars {
    kubelet_lv = "${var.va["kubelet_lv"]}"
    docker_lv  = "${var.va["docker_lv"]}"
    va_lv      = "${var.va["va_lv"]}"
  }
}

data "template_file" "createfs_worker" {
  template = "${file("${path.module}/scripts/createfs_worker.sh.tpl")}"

  vars {
    kubelet_lv = "${var.worker["kubelet_lv"]}"
    docker_lv  = "${var.worker["docker_lv"]}"
  }
}

#NFS Templates
data "template_file" "createfs_nfs" {
  template = "${file("${path.module}/scripts/createfs_nfs.sh.tpl")}"

  vars {
    nfs_lv  = "${var.nfs["nfs_lv"]}"
  }
}

data "template_file" "bootstrap_shared_storage" {
  template = "${file("${path.module}/scripts/bootstrap_shared_storage.tpl")}"

  vars {
    flag_usenfs = "${local.flag_usenfs}"
  }
}

data "template_file" "mount_nfs" {
  template = "${file("${path.module}/scripts/mount_nfs.tpl")}"

  vars {
    nfs_ip       = "${local.flag_usenfs < 1 ? "" : element(split(",", join(",", ibm_compute_vm_instance.nfs.*.ipv4_address_private)), 0)}"
    flag_usenfs  = "${local.flag_usenfs}"
  }
}

#HAProxy Templates
data "template_file" "haproxy_master" {
   count     = "${var.master["nodes"]}"
   template  = "      server master_server$${idx} $${machine}"

   vars {
     idx     = "${count.index + 1}"
     machine = "${element(ibm_compute_vm_instance.master.*.ipv4_address_private, count.index)}"
   }
}

data "template_file" "haproxy_proxy" {
   count     = "${var.proxy["nodes"]}"
   template  = "      server proxy_server$${idx} $${machine}"

   vars {
     idx     = "${count.index + 1}"
     machine = "${element(ibm_compute_vm_instance.proxy.*.ipv4_address_private, count.index)}"
   }
}

data "template_file" "haproxy" {
  template = "${file("${path.module}/scripts/haproxy.cfg.tpl")}"

  vars {
    k8s_api       = "${join(":8001\n",data.template_file.haproxy_master.*.rendered)}:8001\n"
    dashboard     = "${join(":8443\n",data.template_file.haproxy_master.*.rendered)}:8443\n"
    auth          = "${join(":9443\n",data.template_file.haproxy_master.*.rendered)}:9443\n"
    image_manager = "${join(":8600\n",data.template_file.haproxy_master.*.rendered)}:8600\n"
    registry      = "${join(":8500\n",data.template_file.haproxy_master.*.rendered)}:8500\n"
    cam           = "${var.proxy["nodes"] > 0 ? join(":30000\n",data.template_file.haproxy_proxy.*.rendered) : join(":30000\n",data.template_file.haproxy_master.*.rendered)}:30000\n"
    proxy_http    = "${var.proxy["nodes"] > 0 ? join(":80\n",data.template_file.haproxy_proxy.*.rendered) : join(":80\n",data.template_file.haproxy_master.*.rendered)}:80\n"
    proxy_https   = "${var.proxy["nodes"] > 0 ? join(":443\n",data.template_file.haproxy_proxy.*.rendered) : join(":443\n",data.template_file.haproxy_master.*.rendered)}:443\n"
  }
}

#Create HAProxy Node
resource "ibm_compute_vm_instance" "haproxy" {
  lifecycle {
    ignore_changes = ["private_vlan_id"]
  }

  count                = "${var.haproxy["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.haproxy["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.haproxy["cpu_cores"]}"
  memory               = "${var.haproxy["memory"]}"
  disks                = ["${var.haproxy["disk_size"]}"]
  local_disk           = "${var.haproxy["local_disk"]}"
  network_speed        = "${var.haproxy["network_speed"]}"
  hourly_billing       = "${var.haproxy["hourly_billing"]}"
  private_network_only = "${var.haproxy["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]
  private_vlan_id      = "${ibm_compute_vm_instance.boot.0.private_vlan_id}"

  #private_security_group_ids = ["${ibm_security_group.private_outbound.id}","${ibm_security_group.private_inbound.id}"]
  #public_security_group_ids = ["${ibm_security_group.public_outbound.id}","${ibm_security_group.public_inbound_ssh.id}","${ibm_security_group.public_inbound_haproxy.id}","${ibm_security_group.public_inbound_proxy.id}"]

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }

  provisioner "file" {
    content     = "${data.template_file.haproxy.rendered}"
    destination = "~/haproxy.cfg"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/create_nfs.sh"
    destination = "/tmp/create_nfs.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/download_docker.sh"
    destination = "/tmp/download_docker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create_nfs.sh; /tmp/create_nfs.sh",
      "chmod +x /tmp/download_docker.sh; sudo /tmp/download_docker.sh \"${var.icp_source_server}\" \"${var.icp_source_user}\" \"${var.icp_source_password}\" \"${var.icp_docker_path}\" \"/tmp/${basename(var.icp_docker_path)}\"",
      "sudo -H docker run -d --name icp_haproxy -v ~/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro -p 8001:8001 -p 8443:8443 -p 9443:9443 -p 8500:8500 -p 8600:8600 -p 80:80 -p 443:443 -p 30000:30000 --restart=unless-stopped haproxy",
    ]
  }
}

#Create NFS Node
resource "ibm_compute_vm_instance" "nfs" {
  lifecycle {
    ignore_changes = ["private_vlan_id"]
  }

  count                = "${local.flag_usenfs}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.nfs["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.nfs["cpu_cores"]}"
  memory               = "${var.nfs["memory"]}"
  disks                = ["${var.nfs["disk_size"]}", "${local.nfs_datadisk}"]
  local_disk           = "${var.nfs["local_disk"]}"
  network_speed        = "${var.nfs["network_speed"]}"
  hourly_billing       = "${var.nfs["hourly_billing"]}"
  private_network_only = "${var.nfs["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]
  private_vlan_id      = "${ibm_compute_vm_instance.boot.0.private_vlan_id}"

  #private_security_group_ids = ["${ibm_security_group.private_outbound.id}","${ibm_security_group.private_inbound.id}"]
  #public_security_group_ids = ["${ibm_security_group.public_outbound.id}","${ibm_security_group.public_inbound_ssh.id}","${ibm_security_group.public_inbound_nfs.id}","${ibm_security_group.public_inbound_proxy.id}"]

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }
  provisioner "file" {
    content     = "${data.template_file.createfs_nfs.rendered}"
    destination = "/tmp/createfs.sh"
  }
  provisioner "file" {
    content     = "${data.template_file.bootstrap_shared_storage.rendered}"
    destination = "/tmp/bootstrap_shared_storage.sh"
  }
  provisioner "file" {
    source      = "${path.module}/scripts/create_nfs.sh"
    destination = "/tmp/create_nfs.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/createfs.sh; sudo /tmp/createfs.sh",
      "chmod +x /tmp/create_nfs.sh; /tmp/create_nfs.sh",
      "chmod +x /tmp/bootstrap_shared_storage.sh; /tmp/bootstrap_shared_storage.sh",
    ]
  }
}

#Create Boot Node
resource "ibm_compute_vm_instance" "boot" {
  lifecycle {
    ignore_changes = ["private_vlan_id"]
  }

  count                = "${var.boot["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.boot["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.boot["cpu_cores"]}"
  memory               = "${var.boot["memory"]}"
  disks                = ["${var.boot["disk_size"]}"]
  local_disk           = "${var.boot["local_disk"]}"
  network_speed        = "${var.boot["network_speed"]}"
  hourly_billing       = "${var.boot["hourly_billing"]}"
  private_network_only = "${var.boot["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]

  #private_security_group_ids = ["${ibm_security_group.private_outbound.id}","${ibm_security_group.private_inbound.id}"]
  #public_security_group_ids = ["${ibm_security_group.public_outbound.id}","${ibm_security_group.public_inbound_ssh.id}","${ibm_security_group.public_inbound_boot.id}","${ibm_security_group.public_inbound_proxy.id}"]

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }
}

# Create Master Node
resource "ibm_compute_vm_instance" "master" {
  lifecycle {
    ignore_changes = ["private_vlan_id"]
  }

  count                = "${var.master["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.master["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.master["cpu_cores"]}"
  memory               = "${var.master["memory"]}"
  disks                = ["${var.master["disk_size"]}", "${local.master_datadisk}"]
  local_disk           = "${var.master["local_disk"]}"
  network_speed        = "${var.master["network_speed"]}"
  hourly_billing       = "${var.master["hourly_billing"]}"
  private_network_only = "${var.master["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]
  private_vlan_id      = "${ibm_compute_vm_instance.boot.0.private_vlan_id}"

  #private_security_group_ids = ["${ibm_security_group.private_outbound.id}","${ibm_security_group.private_inbound.id}"]
  #public_security_group_ids = ["${ibm_security_group.public_outbound.id}","${ibm_security_group.public_inbound_ssh.id}","${ibm_security_group.public_inbound_master.id}","${ibm_security_group.public_inbound_proxy.id}"]

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }
  provisioner "file" {
    content     = "${data.template_file.createfs_master.rendered}"
    destination = "/tmp/createfs.sh"
  }
  provisioner "file" {
    content     = "${data.template_file.mount_nfs.rendered}"
    destination = "/tmp/mount_nfs.sh"
  }
  provisioner "file" {
    source      = "${path.module}/scripts/create_nfs.sh"
    destination = "/tmp/create_nfs.sh"
  }  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/createfs.sh; sudo /tmp/createfs.sh",
      "chmod +x /tmp/create_nfs.sh; /tmp/create_nfs.sh",
      "chmod +x /tmp/mount_nfs.sh; /tmp/mount_nfs.sh",      
    ]
  }
}

# Create Proxy Node
resource "ibm_compute_vm_instance" "proxy" {
  lifecycle {
    ignore_changes = ["private_vlan_id"]
  }

  count                = "${var.proxy["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.proxy["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.proxy["cpu_cores"]}"
  memory               = "${var.proxy["memory"]}"
  disks                = ["${var.proxy["disk_size"]}", "${local.proxy_datadisk}"]
  local_disk           = "${var.proxy["local_disk"]}"
  network_speed        = "${var.proxy["network_speed"]}"
  hourly_billing       = "${var.proxy["hourly_billing"]}"
  private_network_only = "${var.proxy["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]
  private_vlan_id      = "${ibm_compute_vm_instance.boot.0.private_vlan_id}"

  #private_security_group_ids = ["${ibm_security_group.private_outbound.id}","${ibm_security_group.private_inbound.id}"]
  #public_security_group_ids = ["${ibm_security_group.public_outbound.id}","${ibm_security_group.public_inbound_ssh.id}","${ibm_security_group.public_inbound_proxy.id}"]

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }
  provisioner "file" {
    content     = "${data.template_file.createfs_proxy.rendered}"
    destination = "/tmp/createfs.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/createfs.sh; sudo /tmp/createfs.sh",
    ]
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "cat > ${var.ssh_key_name} <<EOL\n${tls_private_key.ssh.private_key_pem}\nEOL"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "chmod 600 ${var.ssh_key_name}"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "scp -i ${var.ssh_key_name} ${local.ssh_options} ${path.module}/scripts/destroy/delete_node.sh ${var.ssh_user}@${local.icp_boot_node_ip}:/tmp/"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "ssh -i ${var.ssh_key_name} ${local.ssh_options} ${var.ssh_user}@${local.icp_boot_node_ip} \"chmod +x /tmp/delete_node.sh; /tmp/delete_node.sh ${var.icp_version} ${self.ipv4_address_private} proxy\"; echo done"
  }
}

# Create Management Node
resource "ibm_compute_vm_instance" "management" {
  lifecycle {
    ignore_changes = ["private_vlan_id"]
  }

  count                = "${var.management["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.management["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.management["cpu_cores"]}"
  memory               = "${var.management["memory"]}"
  disks                = ["${var.management["disk_size"]}", "${local.management_datadisk}"]
  local_disk           = "${var.management["local_disk"]}"
  network_speed        = "${var.management["network_speed"]}"
  hourly_billing       = "${var.management["hourly_billing"]}"
  private_network_only = "${var.management["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]
  private_vlan_id      = "${ibm_compute_vm_instance.boot.0.private_vlan_id}"

  #private_security_group_ids = ["${ibm_security_group.private_outbound.id}","${ibm_security_group.private_inbound.id}"]
  #public_security_group_ids = ["${ibm_security_group.public_outbound.id}","${ibm_security_group.public_inbound_ssh.id}"]

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }
  provisioner "file" {
    content     = "${data.template_file.createfs_management.rendered}"
    destination = "/tmp/createfs.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/createfs.sh; sudo /tmp/createfs.sh",
    ]
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "cat > ${var.ssh_key_name} <<EOL\n${tls_private_key.ssh.private_key_pem}\nEOL"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "chmod 600 ${var.ssh_key_name}"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "scp -i ${var.ssh_key_name} ${local.ssh_options} ${path.module}/scripts/destroy/delete_node.sh ${var.ssh_user}@${local.icp_boot_node_ip}:/tmp/"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "ssh -i ${var.ssh_key_name} ${local.ssh_options} ${var.ssh_user}@${local.icp_boot_node_ip} \"chmod +x /tmp/delete_node.sh; /tmp/delete_node.sh ${var.icp_version} ${self.ipv4_address_private} management\"; echo done"
  }
}

# Create VA Node
resource "ibm_compute_vm_instance" "va" {
  lifecycle {
    ignore_changes = ["private_vlan_id"]
  }

  count                = "${var.va["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.va["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.va["cpu_cores"]}"
  memory               = "${var.va["memory"]}"
  disks                = ["${var.va["disk_size"]}", "${local.management_datadisk}"]
  local_disk           = "${var.va["local_disk"]}"
  network_speed        = "${var.va["network_speed"]}"
  hourly_billing       = "${var.va["hourly_billing"]}"
  private_network_only = "${var.va["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]
  private_vlan_id      = "${ibm_compute_vm_instance.boot.0.private_vlan_id}"

  #private_security_group_ids = ["${ibm_security_group.private_outbound.id}","${ibm_security_group.private_inbound.id}"]
  #public_security_group_ids = ["${ibm_security_group.public_outbound.id}","${ibm_security_group.public_inbound_ssh.id}"]

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }
  provisioner "file" {
    content     = "${data.template_file.createfs_va.rendered}"
    destination = "/tmp/createfs.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/createfs.sh; sudo /tmp/createfs.sh",
    ]
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "cat > ${var.ssh_key_name} <<EOL\n${tls_private_key.ssh.private_key_pem}\nEOL"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "chmod 600 ${var.ssh_key_name}"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "scp -i ${var.ssh_key_name} ${local.ssh_options} ${path.module}/scripts/destroy/delete_node.sh ${var.ssh_user}@${local.icp_boot_node_ip}:/tmp/"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "ssh -i ${var.ssh_key_name} ${local.ssh_options} ${var.ssh_user}@${local.icp_boot_node_ip} \"chmod +x /tmp/delete_node.sh; /tmp/delete_node.sh ${var.icp_version} ${self.ipv4_address_private} va\"; echo done"
  }
}

# Create Worker Node
resource "ibm_compute_vm_instance" "worker" {
  lifecycle {
    ignore_changes = ["private_vlan_id"]
  }

  count                = "${var.worker["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.worker["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.worker["cpu_cores"]}"
  memory               = "${var.worker["memory"]}"
  disks                = ["${var.worker["disk_size"]}", "${local.worker_datadisk}"]
  local_disk           = "${var.worker["local_disk"]}"
  network_speed        = "${var.worker["network_speed"]}"
  hourly_billing       = "${var.worker["hourly_billing"]}"
  private_network_only = "${var.worker["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]
  private_vlan_id      = "${ibm_compute_vm_instance.boot.0.private_vlan_id}"

  #private_security_group_ids = ["${ibm_security_group.private_outbound.id}","${ibm_security_group.private_inbound.id}"]
  #public_security_group_ids = ["${ibm_security_group.public_outbound.id}","${ibm_security_group.public_inbound_ssh.id}"]
  #post_install_script_uri = "https://raw.githubusercontent.com/pjgunadi/ibm-cloud-private-terraform-softlayer/master/scripts/createfs_worker.sh"

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }
  provisioner "file" {
    content     = "${data.template_file.createfs_worker.rendered}"
    destination = "/tmp/createfs.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/createfs.sh; sudo /tmp/createfs.sh",
    ]
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "cat > ${var.ssh_key_name} <<EOL\n${tls_private_key.ssh.private_key_pem}\nEOL"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "chmod 600 ${var.ssh_key_name}"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "scp -i ${var.ssh_key_name} ${local.ssh_options} ${path.module}/scripts/destroy/delete_node.sh ${var.ssh_user}@${local.icp_boot_node_ip}:/tmp/"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "ssh -i ${var.ssh_key_name} ${local.ssh_options} ${var.ssh_user}@${local.icp_boot_node_ip} \"chmod +x /tmp/delete_node.sh; /tmp/delete_node.sh ${var.icp_version} ${self.ipv4_address_private} worker\"; echo done"
  }
}

#Create Gluster Node
resource "ibm_compute_vm_instance" "gluster" {
  count                = "${var.gluster["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.gluster["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.gluster["cpu_cores"]}"
  memory               = "${var.gluster["memory"]}"
  disks                = ["${var.gluster["disk_size"]}", "${var.gluster["glusterfs"]}"]
  local_disk           = "${var.gluster["local_disk"]}"
  network_speed        = "${var.gluster["network_speed"]}"
  hourly_billing       = "${var.gluster["hourly_billing"]}"
  private_network_only = "${var.gluster["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]
  private_vlan_id      = "${ibm_compute_vm_instance.boot.0.private_vlan_id}"

  #private_security_group_ids = ["${ibm_security_group.private_outbound.id}","${ibm_security_group.private_inbound.id}"]
  #public_security_group_ids = ["${ibm_security_group.public_outbound.id}","${ibm_security_group.public_inbound_ssh.id}"]

  provisioner "local-exec" {
    when    = "destroy"
    command = "cat > ${var.ssh_key_name} <<EOL\n${tls_private_key.ssh.private_key_pem}\nEOL"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "chmod 600 ${var.ssh_key_name}"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "scp -i ${var.ssh_key_name} ${local.ssh_options} ${path.module}/scripts/destroy/delete_gluster.sh ${var.ssh_user}@${local.heketi_ip}:/tmp/"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "ssh -i ${var.ssh_key_name} ${local.ssh_options} ${var.ssh_user}@${local.heketi_ip} \"chmod +x /tmp/delete_gluster.sh; /tmp/delete_gluster.sh ${self.ipv4_address_private} ${var.heketi_admin_pwd}\"; echo done"
  }
}

resource "null_resource" "copy_delete_node" {
  connection {
    host        = "${local.icp_boot_node_ip}"
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/destroy/delete_node.sh"
    destination = "/tmp/delete_node.sh"
  }
}

resource "null_resource" "copy_delete_gluster" {
  count = "${var.install_gluster ? 1 : 0}"
  
  connection {
    host        = "${local.heketi_ip}"
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/destroy/delete_gluster.sh"
    destination = "/tmp/delete_gluster.sh"
  }
}

#Update NFS Server
data "template_file" "update_nfs_server" {
  template = "${file("${path.module}/scripts/update_nfs_server.tpl")}"

  vars {
    master_ips  = "${join(" ", ibm_compute_vm_instance.master.*.ipv4_address_private)}"
    flag_usenfs = "${local.flag_usenfs}"
  }
}

locals {
  nfs_ip = "${local.flag_usenfs < 1 ? "" : element(split(",", join(",", ibm_compute_vm_instance.nfs.*.ipv4_address)),0)}"
}
resource "null_resource" "update_nfs_server" {
  count = "${local.flag_usenfs}"
  connection {
    host        = "${local.nfs_ip}"
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }

  provisioner "file" {
    content     = "${data.template_file.update_nfs_server.rendered}"
    destination = "/tmp/update_nfs_server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/update_nfs_server.sh; /tmp/update_nfs_server.sh",
    ]
  }
}

module "icpprovision" {
  source = "github.com/pjgunadi/terraform-module-icp-deploy?ref=3.1.2"
  # source = "github.com/pjgunadi/terraform-module-icp-deploy?ref=test"

  //Connection IPs
  #icp-ips   = "${concat(ibm_compute_vm_instance.master.*.ipv4_address, ibm_compute_vm_instance.proxy.*.ipv4_address, ibm_compute_vm_instance.management.*.ipv4_address, ibm_compute_vm_instance.va.*.ipv4_address, ibm_compute_vm_instance.worker.*.ipv4_address)}"
  #icp-ips = "${concat(ibm_compute_vm_instance.boot.*.ipv4_address)}"
  icp-ips = ["${local.icp_boot_node_ip}"]
  boot-node = "${local.icp_boot_node_ip}"

  //Configuration IPs
  icp-master     = ["${ibm_compute_vm_instance.master.*.ipv4_address_private}"]
  icp-worker     = ["${ibm_compute_vm_instance.worker.*.ipv4_address_private}"]
  icp-proxy      = ["${split(",",var.proxy["nodes"] == 0 ? join(",",ibm_compute_vm_instance.master.*.ipv4_address_private) : join(",",ibm_compute_vm_instance.proxy.*.ipv4_address_private))}"] #Combined Proxy with Master
  icp-management = ["${split(",",var.management["nodes"] == 0 ? "" : join(",",ibm_compute_vm_instance.management.*.ipv4_address_private))}"]
  icp-va         = ["${split(",",var.va["nodes"] == 0 ? "" : join(",",ibm_compute_vm_instance.va.*.ipv4_address_private))}"]

  # Workaround for terraform issue #10857
  cluster_size    = "${var.boot["nodes"]}"
  master_size     = "${var.master["nodes"]}"
  worker_size     = "${var.worker["nodes"]}"
  proxy_size      = "${var.proxy["nodes"]}"
  management_size = "${var.management["nodes"]}"
  va_size         = "${var.va["nodes"]}"

  icp_source_server   = "${var.icp_source_server}"
  icp_source_user     = "${var.icp_source_user}"
  icp_source_password = "${var.icp_source_password}"
  image_file          = "${var.icp_source_path}"
  docker_installer    = "${var.icp_docker_path}"
  firewall_enabled    = "${var.firewall_enabled}"

  icp-version = "${var.icp_version}"

  icp_configuration = {
    "cluster_name"                 = "${var.cluster_name}"
    "network_cidr"                 = "${var.network_cidr}"
    "service_cluster_ip_range"     = "${var.cluster_ip_range}"
    "ansible_user"                 = "${var.ssh_user}"
    "ansible_become"               = "${var.ssh_user == "root" ? false : true}"
    "default_admin_password"       = "${var.icpadmin_password}"
    "docker_log_max_size"          = "100m"
    "docker_log_max_file"          = "10"
    "cluster_lb_address"           = "${var.haproxy["nodes"] == 0 ? ibm_compute_vm_instance.master.0.ipv4_address : element(split(",", join(",", ibm_compute_vm_instance.haproxy.*.ipv4_address)),0)}"
    "proxy_lb_address"             = "${var.haproxy["nodes"] == 0 ? element(split(",",var.proxy["nodes"] == 0 ? join(",",ibm_compute_vm_instance.master.*.ipv4_address) : join(",",ibm_compute_vm_instance.proxy.*.ipv4_address)),0) : element(split(",", join(",", ibm_compute_vm_instance.haproxy.*.ipv4_address)),0)}"
    "firewall_enabled"             = "${var.firewall_enabled}"
    "auditlog_enabled"             = "${var.auditlog_enabled}"
    "tiller_ciphersuites"          = "${var.tiller_ciphersuites}"
    "etcd_extra_args"              = "${var.etcd_extra_args}"
    "kube_apiserver_extra_args"    = "${var.kube_apiserver_extra_args}"
    "kubelet_extra_args"           = "${var.kubelet_extra_args}"
    "kubelet_nodename"             = "${var.kubelet_nodename}"
    
    "management_services" = {
      "istio" = "${var.management_services["istio"]}"
      "vulnerability-advisor" = "${var.va["nodes"] != 0 ? var.management_services["vulnerability-advisor"] : "disabled"}"
      "storage-glusterfs" = "${var.management_services["storage-glusterfs"]}"
      "storage-minio" = "${var.management_services["storage-minio"]}"
    }
    
    "calico_ipip_enabled" = "${var.calico_network["ipip_enabled"]}"
    "calico_ip_autodetection_method" = "${var.calico_network["interface"]}"
    "ipsec_mesh" = {
      "enable" = "${var.calico_network["ipsec_enabled"]}"
      "subnets" = ["${var.calico_network["subnets"]}"]
      "cipher_suite" = "${var.calico_network["cipher_suite"]}"
    }
  }

  #Gluster
  #Gluster and Heketi nodes are set to worker nodes for demo. Use separate nodes for production
  install_gluster = "${var.install_gluster}"

  gluster_size        = "${var.gluster["nodes"]}"
  gluster_ips         = ["${ibm_compute_vm_instance.gluster.*.ipv4_address}"]
  gluster_svc_ips     = ["${ibm_compute_vm_instance.gluster.*.ipv4_address_private}"]
  device_name         = "/dev/xvdc"                                                   #update according to the device name provided by cloud provider
  heketi_ip           = "${local.heketi_ip}"
  heketi_svc_ip       = "${local.heketi_svc_ip}"
  cluster_name        = "${var.cluster_name}.icp"
  gluster_volume_type = "${var.gluster_volume_type}"
  heketi_admin_pwd    = "${var.heketi_admin_pwd}"
  generate_key        = true

  #icp_pub_keyfile = "${tls_private_key.ssh.public_key_openssh}"
  #icp_priv_keyfile = "${tls_private_key.ssh.private_key_pem"}"

  ssh_user = "${var.ssh_user}"
  ssh_key  = "${tls_private_key.ssh.private_key_pem}"

  bastion_host = "${local.icp_boot_node_ip}"
  bastion_user = "${var.ssh_user}"
  bastion_private_key = "${tls_private_key.ssh.private_key_pem}"
}
