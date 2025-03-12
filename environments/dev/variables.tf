variable "resource_group_name" {}
variable "location" {
  default = "eastus"
}
variable "deploy_aks" {
  description = "Whether to deploy the AKS cluster in the DEV environment"
  type        = bool
  default     = false
}
variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
  default     = null
}
variable "admin_group_object_id" {
  description = "Azure AD group object ID for AKS admins"
  type        = string
}
variable "tenant_id" {
  description = "Azure AD Tenant ID for AKS RBAC integration"
  type        = string
}
