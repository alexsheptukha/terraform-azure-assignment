provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name = "dev-tfstate-rg"
    container_name      = "tfstate"
    key                 = "terraform.tfstate"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "storage_account" {
  source               = "../../modules/storage_account"
  storage_account_name = "devstorage${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
}

module "aks" {
  count                  = var.deploy_aks ? 1 : 0
  source                 = "../../modules/aks"
  aks_name               = "dev-aks"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  dns_prefix             = "devaks"
  admin_group_object_ids = [var.admin_group_object_id]
  tenant_id              = var.tenant_id
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
