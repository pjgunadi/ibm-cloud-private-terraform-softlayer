provider "ibm" {
  bluemix_api_key    = "${var.ibm_bmx_api_key}"
  softlayer_username = "${var.ibm_sl_username}"
  softlayer_api_key  = "${var.ibm_sl_api_key}"
}
resource "ibm_compute_ssh_key" "cam_public_key" {
  label      = "${var.ssh_key_name}"
  public_key = "${var.ssh_public_key}"
}
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}
resource "ibm_compute_ssh_key" "temp_public_key" {
  label = "key-temp"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}
# Create Master Node
resource "ibm_compute_vm_instance" "master" {
  count                = "${var.master["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.master["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.master["cpu_cores"]}"
  memory               = "${var.master["memory"]}"
  disks                = ["${split(",",var.master["disk_size"])}"]
  local_disk           = "${var.master["local_disk"]}"
  network_speed        = "${var.master["network_speed"]}"
  hourly_billing       = "${var.master["hourly_billing"]}"
  private_network_only = "${var.master["private_network_only"]}"
  user_metadata        = "#!/bin/bash\nsed -i \"s/^PasswordAuthentication yes$/PasswordAuthentication no/\" /etc/ssh/sshd_config && systemctl restart sshd"
  ssh_key_ids = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  post_install_script_uri = "https://raw.githubusercontent.com/pjgunadi/ibm-cloud-private-terraform-softlayer/master/scripts/createfs_master.sh"
}
# Create Proxy Node
resource "ibm_compute_vm_instance" "proxy" {
  count                = "${var.proxy["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.proxy["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.proxy["cpu_cores"]}"
  memory               = "${var.proxy["memory"]}"
  disks                = ["${split(",",var.proxy["disk_size"])}"]
  local_disk           = "${var.proxy["local_disk"]}"
  network_speed        = "${var.proxy["network_speed"]}"
  hourly_billing       = "${var.proxy["hourly_billing"]}"
  private_network_only = "${var.proxy["private_network_only"]}"
  user_metadata        = "#!/bin/bash\nsed -i \"s/^PasswordAuthentication yes$/PasswordAuthentication no/\" /etc/ssh/sshd_config && systemctl restart sshd"
  ssh_key_ids = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  post_install_script_uri = "https://raw.githubusercontent.com/pjgunadi/ibm-cloud-private-terraform-softlayer/proxy/scripts/createfs_proxy_worker.sh"
}
# Create Management Node
resource "ibm_compute_vm_instance" "management" {
  count                = "${var.management["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.management["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.management["cpu_cores"]}"
  memory               = "${var.management["memory"]}"
  disks                = ["${split(",",var.management["disk_size"])}"]
  local_disk           = "${var.management["local_disk"]}"
  network_speed        = "${var.management["network_speed"]}"
  hourly_billing       = "${var.management["hourly_billing"]}"
  private_network_only = "${var.management["private_network_only"]}"
  user_metadata        = "#!/bin/bash\nsed -i \"s/^PasswordAuthentication yes$/PasswordAuthentication no/\" /etc/ssh/sshd_config && systemctl restart sshd"
  ssh_key_ids = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  post_install_script_uri = "https://raw.githubusercontent.com/pjgunadi/ibm-cloud-private-terraform-softlayer/management/scripts/createfs_management.sh"
}
# Create Worker Node
resource "ibm_compute_vm_instance" "worker" {
  count                = "${var.worker["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.worker["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.worker["cpu_cores"]}"
  memory               = "${var.worker["memory"]}"
  disks                = ["${split(",",var.worker["disk_size"])}"]
  local_disk           = "${var.worker["local_disk"]}"
  network_speed        = "${var.worker["network_speed"]}"
  hourly_billing       = "${var.worker["hourly_billing"]}"
  private_network_only = "${var.worker["private_network_only"]}"
  user_metadata        = "#!/bin/bash\nsed -i \"s/^PasswordAuthentication yes$/PasswordAuthentication no/\" /etc/ssh/sshd_config && systemctl restart sshd"
  ssh_key_ids = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  post_install_script_uri = "https://raw.githubusercontent.com/pjgunadi/ibm-cloud-private-terraform-softlayer/worker/scripts/createfs_proxy_worker.sh"
}

module "icpprovision" {
  source = "github.com/pjgunadi/terraform-module-icp-deploy"
  //Connection IPs
  icp-ips = "${concat(ibm_compute_vm_instance.master.*.ipv4_address, ibm_compute_vm_instance.proxy.*.ipv4_address, ibm_compute_vm_instance.management.*.ipv4_address, ibm_compute_vm_instance.worker.*.ipv4_address)}"
  boot-node = "${element(ibm_compute_vm_instance.master.*.ipv4_address, 0)}"

  //Configuration IPs
  icp-master = ["${ibm_compute_vm_instance.master.*.ipv4_address_private}"]
  icp-worker = ["${ibm_compute_vm_instance.worker.*.ipv4_address_private}"]
  icp-proxy = ["${ibm_compute_vm_instance.proxy.*.ipv4_address_private}"]
  icp-management = ["${ibm_compute_vm_instance.management.*.ipv4_address_private}"]

  enterprise-edition = false
  icp-version = "${var.icp_version}"

  /* Workaround for terraform issue #10857
  When this is fixed, we can work this out autmatically */
  cluster_size  = "${var.master["nodes"] + var.worker["nodes"] + var.proxy["nodes"] + var.management["nodes"]}"

  icp_configuration = {
    "network_cidr"              = "172.16.0.0/16"
    "service_cluster_ip_range"  = "192.168.0.1/24"
    "ansible_user"              = "${var.ssh_user}"
    "ansible_become"            = "${var.ssh_user == "root" ? false : true}"
    "default_admin_password"    = "${var.icpadmin_password}"
    "calico_ipip_enabled"       = "true"
    "cluster_access_ip"         = "${element(ibm_compute_vm_instance.master.*.ipv4_address, 0)}"
  }

  generate_key = true
  #icp_pub_keyfile = "${tls_private_key.ssh.public_key_openssh}"
  #icp_priv_keyfile = "${tls_private_key.ssh.private_key_pem"}"
    
  ssh_user  = "${var.ssh_user}"
  ssh_key   = "${tls_private_key.ssh.private_key_pem}"
} 
