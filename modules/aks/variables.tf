variable "aks_name" {}
variable "resource_group_name" {}
variable "location" {}
variable "dns_prefix" {}
variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs for AKS admins"
  type        = list(string)
  default     = []
}
variable "tenant_id" {
  description = "Azure AD Tenant ID for AKS RBAC integration"
  type        = string
}
