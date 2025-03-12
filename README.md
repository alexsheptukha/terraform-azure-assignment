# Terraform Azure Pipeline

This repository automates Terraform deployments to Azure for DEV and QA environments using GitHub Actions.

## Setup
1. **Azure Prerequisites**:
   - Create a resource group `tfstate-rg` and a storage account (e.g., `tfstate1698765432`) for Terraform state.
   - Create a service principal and store its JSON in GitHub Secrets as `AZURE_CREDENTIALS`.
   - Store the storage account name as `TFSTATE_STORAGE_ACCOUNT_NAME` and key as `TFSTATE_STORAGE_KEY` in GitHub Secrets.

2. **Repository Structure**:
   - `modules/`: Reusable Terraform modules (Storage Account, Key Vault, AKS).
   - `environments/`: DEV (Storage Account + optional AKS) and QA (Key Vault) configurations.
   - `.github/workflows/`: GitHub Actions pipeline.

## Deployment
- **Push to `main`**: Runs `terraform plan` for the DEV environment (AKS off by default).
- **Manual Workflow**:
  - Go to Actions > Run workflow.
  - Select `environment` (`dev` or `qa`) and `deploy_aks` (`true`/`false` for DEV AKS).
  - Runs `plan` and `apply` with the specified settings.

## Resources
- **DEV**: Resource Group, Storage Account, optional AKS cluster (controlled by `deploy_aks` variable).
- **QA**: Resource Group, Key Vault.

## Notes
- Resource names use `random_string` for uniqueness, persisted via the `tfstate` backend.
- AKS in DEV is optional—set `deploy_aks` to `true` to include it (defaults to `false`).
- Credentials and backend config use GitHub Secrets for security.
