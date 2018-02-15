output "icp_url" {
  value = "https://${softlayer_virtual_guest.master.0.ipv4_address}:8443"
}
