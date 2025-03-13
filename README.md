# Terraform Azure Pipeline

This repository contains a GitHub Actions pipeline to deploy Terraform code to an Azure Subscription, managing two isolated environments: DEV and QA. Each environment has its own dedicated Azure Resource Group for resources and a separate Resource Group for Terraform state storage, ensuring strict security and isolation.

## Project Structure
- **modules/**: Reusable Terraform modules for provisioning resources:
  - storage_account: Deploys an Azure Storage Account (used in DEV).
  - key_vault: Deploys an Azure Key Vault (used in QA).
  - aks: Deploys an optional Azure Kubernetes Service (AKS) cluster (used in DEV).
- **environments/**:
  - dev/: Configures a Resource Group, Storage Account, and optional AKS cluster.
  - qa/: Configures a Resource Group and Key Vault.
- **.github/workflows/deploy.yml**: GitHub Actions pipeline for Terraform deployment.


## Environments
- **DEV**:
  - Resource Group: `dev-rg`
  - Resources: Azure Storage Account, optional AKS cluster (controlled by `deploy_aks` variable).
  - State: Stored in `dev-tfstate-rg` (Storage Account: `<dev-tfstate-account-name>`, container `tfstate`, file `terraform.tfstate`).
- **QA**:
  - Resource Group: `qa-rg`
  - Resources: Azure Key Vault.
  - State: Stored in `qa-tfstate-rg` (Storage Account: `<qa-tfstate-account-name>`, container `tfstate`, file `terraform.tfstate`).

## Prerequisites
 **Azure Setup**:

   - Create two Resource Groups for Terraform state:
   
     ```bash
     az group create --name "dev-tfstate-rg" --location "eastus"
     az group create --name "qa-tfstate-rg" --location "eastus"
     ```
     
   - Create Storage Accounts and containers for each:
   
     ```bash
     # For DEV
     az storage account create --name "devtfstate$(date +%s)" --resource-group "dev-tfstate-rg" --sku Standard_LRS
     az storage container create --name "tfstate" --account-name "<dev-tfstate-account-name>"
     
     # For QA
     az storage account create --name "qatfstate$(date +%s)" --resource-group "qa-tfstate-rg" --sku Standard_LRS
     az storage container create --name "tfstate" --account-name "<qa-tfstate-account-name>"
     ```
   - Save the Storage Account names and access keys.
   
   ```bash
   # For QA
   az storage account keys list --resource-group "qa-tfstate-rg" --account-name <qa-tfstate-account-name> --query "[0].value" -o tsv
   # For DEV
   az storage account keys list --resource-group "dev-tfstate-rg" --account-name <dev-tfstate-account-name> --query "[0].value" -o tsv
   ```

**Service Principal**:

   - Create a service principal for GitHub Actions:
   
     ```bash
     az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes /subscriptions/<subscription-id> --sdk-auth
     ```
     
   - Save the JSON output.
   
**Create Admin group in Azure AD for AKS access**

```bash
az ad group create --display-name "AKS-Admins" --mail-nickname "AKSAdmins" --description "AKS Admins for DEV"
# save object id for later use
az ad group show --group "AKS-Admins" --query id -o tsv
```
    
**Assign AKS access for a created group**

```bash
az role assignment create --assignee <id-from-above> \
--role "Azure Kubernetes Service Cluster Admin Role" \
--scope "/subscriptions/<subscription-id>/resourceGroups/dev-rg"
```
    
**Get kubeconfig**

```bash
az aks get-credentials --resource-group dev-rg --name dev-aks
```
    
**Get Tenant ID**

```bash
az account show --query tenantId -o tsv
```

**GitHub Secrets**:

   - `AZURE_CREDENTIALS`: Full JSON from the service principal.
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID.
   - `DEV_TFSTATE_STORAGE_ACCOUNT_NAME`: DEV Storage Account name (e.g., `devtfstate1698765432`).
   - `DEV_TFSTATE_STORAGE_KEY`: DEV Storage Account access key.
   - `QA_TFSTATE_STORAGE_ACCOUNT_NAME`: QA Storage Account name (e.g., `qatfstate1698765433`).
   - `QA_TFSTATE_STORAGE_KEY`: QA Storage Account access key.
   - `AKS_ADMIN_GROUP_ID`: AKS admin group id - for access to the Kubernetes cluster
   - `AZURE_TENANT_ID`: Your Tenant ID

**GitHub Environments**:

   - In GitHub > Settings > Environments, create:
     - `dev`: Add yourself (or a team) as a required reviewer.
     - `qa`: Add yourself (or a team) as a required reviewer.
   - Enable "Required reviewers" under Deployment protection rules for manual approval.

## Deployment Process
### Pipeline Overview
- **Trigger**:
  - On `workflow_dispatch`: Runs `terraform plan` and waits for manual approval before `terraform apply`.
- **Steps**:
  1. `Terraform Init`: Initializes the backend with environment-specific Storage Accounts.
  2. `Terraform Plan`: Generates a plan (`tfplan`) based on the selected environment.
  3. `Terraform Apply`: Applies the plan after manual approval (only for `workflow_dispatch`).

### Running the Pipeline

**Manual Deployment**:
   - Go to GitHub > Actions > `Terraform Deployment` > Run workflow.
   - Inputs:
     - `environment`: `dev` or `qa`.
     - `deploy_aks`: `true` or `false` (only for DEV, defaults to `false`).
   - Steps:
     1. After `Terraform Plan`, review the plan in the logs.
     2. Approve the deployment:
        - Click "Review deployments" in the workflow run.
        - Select the environment (`dev` or `qa`) and click "Approve and deploy".
     3. `Terraform Apply` executes and deploys the resources.
     
Deploying on push is disabled for security reasons.

## Security & Best Practices
- **Credentials**: Stored in GitHub Secrets (`AZURE_CREDENTIALS`, `*_TFSTATE_STORAGE_*`).
- **State Isolation**: Separate `tfstate` files in distinct Resource Groups (`dev-tfstate-rg`, `qa-tfstate-rg`) for DEV and QA.
- **Access Control**: 
  - Configure RBAC in Azure to limit access to `dev-tfstate-rg` and `qa-tfstate-rg` (e.g., `Contributor` role for specific teams).
  - GitHub Environments require manual approval by authorized reviewers.
- - **AKS Security**: Advanced security configuration including a private cluster (API accessible only via VNet), Azure AD integration with RBAC for fine-grained access control, Calico network policies for pod traffic isolation, Network Security Group (NSG) for subnet protection, and Azure Monitor integration for logging and diagnostics.

## Resources Deployed
- **DEV**:
  - Resource Group: `dev-rg`.
  - Storage Account: `devstorage<random-suffix>` (lowercase, 8 characters).
  - Optional AKS: `dev-aks` (enabled via `deploy_aks`).
- **QA**:
  - Resource Group: `qa-rg`.
  - Key Vault: `qa-kv-<random-suffix>`.

## Notes
- Resource names include a `random_string` suffix for uniqueness, persisted in the respective `tfstate` files.
- The AKS cluster in DEV is optional and defaults to `false`.
- Manual approval ensures changes are reviewed before deployment, enhancing security.

## Troubleshooting
- **Plan fails**: Check GitHub Secrets and Terraform variable definitions.
- **Apply hangs**: Verify that the environment (`dev` or `qa`) has been approved in GitHub Actions.
- **Resource errors**: Ensure Azure credentials have sufficient permissions (`Contributor` role recommended).
