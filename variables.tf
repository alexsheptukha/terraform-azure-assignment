variable "location" {
  description = "The Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "The Azure tenant ID"
  type        = string
  default     = null
}

variable "tfstate_storage_account_name" {
  description = "The name of the Azure Storage Account for Terraform state"
  type        = string
  default     = null
}
