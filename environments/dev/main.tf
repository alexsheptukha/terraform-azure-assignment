provider "azurerm" {
  features {}
  subscription_id=var.subscription_id
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = var.tfstate_storage_account_name
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "storage_account" {
  source              = "../../modules/storage_account"
  storage_account_name = "devstorage${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

module "aks" {
  count               = var.deploy_aks ? 1 : 0
  source              = "../../modules/aks"
  aks_name            = "dev-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = "devaks"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper = false
}
