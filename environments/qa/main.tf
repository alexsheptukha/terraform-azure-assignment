provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "qa-tfstate-rg"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "key_vault" {
  source             = "../../modules/key_vault"
  key_vault_name     = "qa-kv-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
