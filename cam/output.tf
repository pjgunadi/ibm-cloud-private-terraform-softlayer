output "icp_url" {
  value = "https://${element(ibm_compute_vm_instance.master.*.ipv4_address, 0)}:8443"
}
