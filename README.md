# Terraform Template for ICP Deployment in IBM SoftLayer

## Before you start
You need a Softlayer account and be aware that **applying this template may incur charges to your Softlayer account**.

## Summary
This terraform template perform the following tasks:
- Provision Softlayer environment for IBM Cloud Private
- [Call ICP Provisioning Module](https://github.com/pjgunadi/terraform-module-icp-deploy)

### Prerequisite: Create IBM Cloud Infrastructure API Key
1. Login to IBM Cloud
2. Navigate to `Infrastructure`
3. On the IBM CLoud Infrastructure dashboard, find **Account Snapshot** section and click [Users](https://control.bluemix.net/account/users#clearAll=true&status=ALL)
4. On user record row, click **Actions** dropdown to Create/Show API Key

## Deployment step from Terraform CLI
1. Clone this repository: `git clone https://github.com/pjgunadi/ibm-cloud-private-terraform-softlayer.git`
2. [Download terraform](https://www.terraform.io/) if you don't have one
3. Login to IBM Cloud Infrastructure (SoftLayer) and create an API Username and API Key
4. Rename [terraform_tfvars.sample](terraform_tfvars.sample) file as `terraform.tfvars` and update the input values as needed.
5. Initialize Terraform
```
terraform init
```
6. Review Terraform plan
```
terraform plan
```
7. Apply Terraform template
```
terraform apply
```
## Add/Remove Worker Nodes
1. Edit existing deployed terraform variable e.g. `terraform.tfvars`
2. Increase/decrease the `nodes` under the `worker` map variable. Example:
```
worker = {
    nodes       = "4"
    name        = "worker"
    cpu_cores   = "2"
    disk_size   = "25" // GB
    kubelet_lv  = "10"
    docker_lv   = "89"
    local_disk  = false
    memory      = "8192"
    network_speed = "1000"
    private_network_only = false
    hourly_billing = true
}
```
3. Re-apply terraform template:
```
terraform plan
terraform apply -auto-approve
```
**Note:** 
- The data disk size is the sum of LV variables + 1 (e.g kubelet_lv + docker_lv + 1).
- The block storage size that can be ordered from IBM Cloud Infrastructure, should match to one of the following: 20GB, 40GB, 80GB, 100GB, 250GB, 500GB, and size between 1,000GB to 12,000GB with increment of 1,000GB

## ICP and Gluster Provisioning Module
The ICP and GlusterFS Installation is performed by [ICP Provisioning module](https://github.com/pjgunadi/terraform-module-icp-deploy) 
