# Terraform Template for ICP Deployment in IBM SoftLayer

## Before you start
You need a Softlayer account and be aware that **applying this template may incur charges to your Softlayer account**.

## Summary
This terraform template perform the following tasks:
- Provision Softlayer environment for IBM Cloud Private
- [Call ICP Provisioning Module](https://github.com/pjgunadi/terraform-module-icp-deploy)

## Input
| Variable      | Description    | Sample Value |
| ------------- | -------------- | ------------ |
| ibm_sl_username    | Softlayer Username  | xxxxxxxxxxxx |
| ibm_sl_api_key    | Softlayer API Key | xxxxxxxxxxxx |
| datacenter        | Softlayer Datacenter Code     | sgn01 |
| os_reference      | Softlayer OS Reference Code. Choose only Ubuntu or RHEL Image | UBUNTU_16_64 (ubuntu), REDHAT_7_64 (rhel) |
| ssh_key_name | Public key label to be added in Softlayer | sl-key |
| ssh_public_key | Your public key string | sha-rsa AAAA.... |
| ssh_user | Login user to ICP instances | root |
| master | Master nodes information | *see default values in variables.tf* |
| proxy | Proxy node information | *see default values in variables.tf* |
| worker | Worker node information | *see default values in variables.tf* |
| management | Management node information | *see default values in variables.tf* |

## Deployment step from Terraform CLI
1. Clone this repository: `git clone https://github.com/pjgunadi/ibm-cloud-private-terraform-softlayer.git`
2. [Download terraform](https://www.terraform.io/) if you don't have one
3. [Download and apply IBM terraform plugin](https://github.com/IBM-Cloud/terraform-provider-ibm/releases)
4. Create terraform variable file with your input value e.g. `terraform.tfvars`
5. Apply the template
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
    disk_size   = "25 75" // GB
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

## Deployment step from IBM Cloud Automation Manager (CAM)
1. Login to CAM
2. Navigate to Library > Template, and click **Create Template**
3. Select tab **From GitHub**
4. Type the **GitHub Repository URL:** `https://github.com/pjgunadi/ibm-cloud-private-terraform-softlayer`
5. Type the **GitHub Repository sub-directory:** `cam`
6. Click **Create**
7. Set **Cloud Provider** value to `IBM`
8. Save the template

## ICP Provisioning Module
This [ICP Provisioning module](https://github.com/pjgunadi/terraform-module-icp-deploy) is forked from [IBM Cloud Architecture](https://github.com/ibm-cloud-architecture/terraform-module-icp-deploy)
with few modifications:
- Added Management nodes section
- Separate Local IP and Public IP variables
- Added boot-node IP variable

