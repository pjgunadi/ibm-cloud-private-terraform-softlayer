# ICP Deployment in IBM Cloud Infrastructure with IBM CAM

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

## Deployment step from IBM CAM
1. Login into IBM CAM
2. Create Cloud Connection to IBM Cloud Infrastructure with the API Key from the prerequisite step
3. Create Template with the following details:
  - From GitHub
  - GitHub Repository URL: `https://github.com/pjgunadi/ibm-cloud-private-terraform-softlayer`
  - GitHub Repository sub-directory: `cam`
4. Click `Create` and `Save`
5. Deploy the template

## Add/Remove Worker Nodes
1. Open Deployed Instance in CAM
2. Open `Modify` tab
3. Click `Next`
4. Increase/decrease the **Worker Node** `nodes` attribute
5. Click `Plan Changes`
6. Review the plan in the Log Output and click `Apply Changes`

**Note:** 
- The data disk size is the sum of LV variables + 1 (e.g kubelet_lv + docker_lv + 1).
- The block storage size that can be ordered from IBM Cloud Infrastructure, should match to one of the following: 20GB, 40GB, 80GB, 100GB, 250GB, 500GB, and size between 1,000GB to 12,000GB with increment of 1,000GB

## ICP and Gluster Provisioning Module
The ICP and GlusterFS Installation is performed by [ICP Provisioning module](https://github.com/pjgunadi/terraform-module-icp-deploy) 
