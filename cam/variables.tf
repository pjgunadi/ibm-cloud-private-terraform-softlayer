variable ssh_key_name {
    description = "SSH Public Key Label"
}
variable ssh_public_key {
    description = "SSH Public Key"
    default = ""
}
variable "ssh_user" {
    description = "SSH User"
    default = "root"
}
variable "icpadmin_password" {
    description = "ICP admin password"
    default = "admin"
}
variable "icp_version" {
    description = "ICP Version"
    default = "2.1.0"
}
variable datacenter {
    description = "Softlayer Data Center code"
    default = "sgn01"
}
variable "domain" {
    description = "Instance Domain"
    default = "icp.demo"
}
variable "os_reference" {
    description = "OS Reference Code: ubuntu: UBUNTU_16_64 Redhat: REDHAT_7_64"
    default = "UBUNTU_16_64"
}
##### ICP Instance details ######
variable "instance_prefix" {
    default = "icp"
}
variable "master" {
  type = "map"
  default = {
    nodes       = "1"
    name        = "master"
    cpu_cores   = "4"
    disk_size   = "25,75" // GB
    local_disk  = false
    memory      = "8192"
    network_speed = "100"
    private_network_only = false
    hourly_billing = true
  }
}
variable "proxy" {
  type = "map"
  default = {
    nodes       = "1"
    name        = "proxy"
    cpu_cores   = "2"
    disk_size   = "25,75" // GB
    local_disk  = false
    memory      = "4096"
    network_speed = "100"
    private_network_only = false
    hourly_billing = true
  }
}
variable "management" {
  type = "map"
  default = {
    nodes       = "1"
    name        = "management"
    cpu_cores   = "4"
    disk_size   = "25,75" // GB
    local_disk  = false
    memory      = "8192"
    network_speed = "100"
    private_network_only = false
    hourly_billing = true
  }
}
variable "worker" {
  type = "map"
  default = {
    nodes       = "3"
    name        = "worker"
    cpu_cores   = "2"
    disk_size   = "25,75" // GB
    local_disk  = false
    memory      = "4096"
    network_speed = "100"
    private_network_only = false
    hourly_billing = true
  }
}
