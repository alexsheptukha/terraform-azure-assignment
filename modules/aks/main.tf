resource "azurerm_virtual_network" "aks_vnet" {
  name                = "${var.aks_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.aks_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.aks_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "aks_nsg_assoc" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

resource "azurerm_log_analytics_workspace" "aks_logs" {
  name                = "${var.aks_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = "1.28"

  private_cluster_enabled = true

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    tenant_id = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled = true
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  oms_agent {
    enabled = true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  }

  auto_scaler_profile {
    balance_similar_node_groups = true
  }

  automatic_upgrade_channel = "stable"
}

resource "azurerm_kubernetes_cluster_node_pool" "aks_node_pool" {
  name                  = "autoscale"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D2_v2"
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 3
  mode                  = "User"
}
