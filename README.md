# Terraform Template for ICP Deployment in IBM SoftLayer

## Before you start
You need a Softlayer account and be aware that **applying this template may incur charges to your Softlayer account**.

## Summary
This terraform template perform the following tasks:
- Provision Softlayer environment for IBM Cloud Private
- [Call ICP Provisioning Module](https://github.com/pjgunadi/terraform-module-icp-deploy)

## Deployment step from Terraform CLI
1. Clone this repository: `git clone https://github.com/pjgunadi/ibm-cloud-private-terraform-softlayer.git`
2. [Download terraform](https://www.terraform.io/) if you don't have one
3. [Download and install IBM terraform plugin](https://github.com/IBM-Cloud/terraform-provider-ibm/releases)
4. Login to IBM Cloud Infrastructure (SoftLayer) and create an API Username and API Key. Omit this step if you already have one
5. Create terraform variable file with your input value e.g. `terraform.tfvars`. See the sample file [terraform_tfvars.sample](terraform_tfvars.sample)
6. Apply the template
```
terraform init
terraform plan
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
    memory      = "4096"
    network_speed = "100"
    private_network_only = false
    hourly_billing = true
}
```
2. Re-apply terraform template:
```
terraform plan
terraform apply -auto-approve
```
## Input
| Variable      | Description    | Sample Value |
| ------------- | -------------- | ------------ |
| ibm_sl_username    | Softlayer Username  | xxxxxxxxxxxx |
| ibm_sl_api_key    | Softlayer API Key | xxxxxxxxxxxx |
| datacenter        | Softlayer Datacenter Code     | sng01 |
| os_reference      | Softlayer OS Reference Code. Choose only Ubuntu or RHEL Image | UBUNTU_16_64 (ubuntu), REDHAT_7_64 (rhel) |
| instance_prefix | VM name prefix | icp |
| domain | Operating System Domain | icp.demo |
| ssh_key_name | Public key label to be added in Softlayer | sl-key |
| ssh_user | Login user to ICP instances | root |
| icp_version | ICP Version and Flavor to install | 2.1.0.1 |
| cluster_name | ICP Cluster name | mycluster |
| install_gluster | Install GlusterFS Flag | true |
| master | Master nodes information | *see default values in variables.tf* |
| proxy | Proxy node information | *see default values in variables.tf* |
| management | Management node information | *see default values in variables.tf* |
| worker | Worker node information | *see default values in variables.tf* |
| gluster | Gluster storage node information | *see default values in variables.tf* |

## ICP Provisioning Module
The ICP and GlusterFS Installation is performed by [ICP Provisioning module](https://github.com/pjgunadi/terraform-module-icp-deploy) 


