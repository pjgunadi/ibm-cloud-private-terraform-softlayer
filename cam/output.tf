output "icp_url" {
  value = "https://${ibm_compute_vm_instance.master.0.ipv4_address}:8443"
}
