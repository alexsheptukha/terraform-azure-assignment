variable "resource_group_name" {}
variable "location" {
  default = "eastus"
}
variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
  default     = null
}
