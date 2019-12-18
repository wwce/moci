data "azurerm_resource_group" "existing_vnet_rg" {
  name = var.vnet_rg
}

data "azurerm_resource_group" "existing_security_rg" {
  name = var.security_rg
}

data "azurerm_virtual_network" "existing_vnet" {
  name                = "vnet-hub-prod-001"
  resource_group_name = "rg-networking-prod-001"
}

resource "azurerm_storage_account" "fwinbootstrapstor" {
  name                     = var.bootstrap_store_name
  resource_group_name      = data.azurerm_resource_group.existing_vnet_rg.name
  location                 = data.azurerm_resource_group.existing_vnet_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = var.dev-environment
  }
}
resource "azurerm_storage_account" "fwoutbootstrapstor" {
  name                     = var.bootstrap_store_name
  resource_group_name      = data.azurerm_resource_group.existing_vnet_rg.name
  location                 = data.azurerm_resource_group.existing_vnet_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = var.dev-environment
  }
}

#File share
resource "azurerm_storage_share" "in_fw_palo_fileshare" {
 name                 = var.in_fw_bootstrap_file_share
 storage_account_name = azurerm_storage_account.fwinbootstrapstor.name
 quota                = 1
}
resource "azurerm_storage_share" "out_fw_palo_fileshare" {
 name                 = var.out_fw_bootstrap_file_share
 storage_account_name = azurerm_storage_account.fwoutbootstrapstor.name
 quota                = 1
}
# File share directory
resource "azurerm_storage_share_directory" "out_fw_fs_dir" {
  name = element([
    var.palo_fileshare_directories,
    var.palo_fileshare_directories1,
    var.palo_fileshare_directories2,
    var.palo_fileshare_directories3], count.index)
  share_name = azurerm_storage_share.out_fw_palo_fileshare.name
  storage_account_name = azurerm_storage_account.fwoutbootstrapstor.name
  count = length(var.palo_fileshare_directories)
}

resource "azurerm_storage_share_directory" "in_fw_fs_dir" {
  name = element([
    var.palo_fileshare_directories,
    var.palo_fileshare_directories1,
    var.palo_fileshare_directories2,
    var.palo_fileshare_directories3], count.index)
  share_name = azurerm_storage_share.in_fw_palo_fileshare.name
  storage_account_name = azurerm_storage_account.fwinbootstrapstor.name
  count = length(var.palo_fileshare_directories)
}

