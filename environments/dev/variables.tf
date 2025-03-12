variable "resource_group_name" {}
variable "location" {
  default = "eastus"
}
variable "deploy_aks" {
  description = "Whether to deploy the AKS cluster in the DEV environment"
  type        = bool
  default     = false
}
