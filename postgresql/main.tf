provider "azurerm" {
  features {}
  subscription_id = ""
}

resource "azurerm_resource_group" "postgresql-cluster-v1" {
  name     = "postgresql-cluster-v1"
  location = "West US 2"
}

resource "azurerm_virtual_network" "postgresql-cluster-v1" {
  name                = "postgresql-cluster-v1-vn2"
  location            = azurerm_resource_group.postgresql-cluster-v1.location
  resource_group_name = azurerm_resource_group.postgresql-cluster-v1.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "postgresql-cluster-v1" {
  name                 = "postgresql-cluster-v1-sn2"
  resource_group_name  = azurerm_resource_group.postgresql-cluster-v1.name
  virtual_network_name = azurerm_virtual_network.postgresql-cluster-v1.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
resource "azurerm_private_dns_zone" "postgresql-cluster-v1" {
  name                = "postgresql-cluster-v1.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.postgresql-cluster-v1.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql-cluster-v1" {
  name                  = "postgresql-cluster-v1VnetZone2.com"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql-cluster-v1.name
  virtual_network_id    = azurerm_virtual_network.postgresql-cluster-v1.id
  resource_group_name   = azurerm_resource_group.postgresql-cluster-v1.name
  depends_on            = [azurerm_subnet.postgresql-cluster-v1]
}

resource "azurerm_postgresql_flexible_server" "postgresql-cluster-v1" {
  name                          = "postgresql-cluster-v1-master"
  resource_group_name           = azurerm_resource_group.postgresql-cluster-v1.name
  location                      = azurerm_resource_group.postgresql-cluster-v1.location
  version                       = "12"
  delegated_subnet_id           = azurerm_subnet.postgresql-cluster-v1.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql-cluster-v1.id
  public_network_access_enabled = false
  administrator_login           = "psqladmin"
  administrator_password        = "H@Sh1CoR3!"
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "GP_Standard_D2s_v3"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql-cluster-v1]

}

# First Read Replica
resource "azurerm_postgresql_flexible_server" "replica1" {
  name                   = "postgresql-cluster-v1-rep1"
  resource_group_name    = azurerm_resource_group.postgresql-cluster-v1.name
  location               = "Japan East"
  source_server_id       = azurerm_postgresql_flexible_server.postgresql-cluster-v1.id
  zone                   = "2"
  administrator_login           = "psqladmin"
  administrator_password        = "H@Sh1CoR3!"
  sku_name   = "GP_Standard_D2s_v3"
  version                       = "12"
}

# Second Read Replica
resource "azurerm_postgresql_flexible_server" "replica2" {
  name                   = "postgresql-cluster-v1-rep2"
  resource_group_name    = azurerm_resource_group.postgresql-cluster-v1.name
  location               = "Italy North"
  source_server_id       = azurerm_postgresql_flexible_server.postgresql-cluster-v1.id
  zone                   = "3"
  administrator_login           = "psqladmin"
  administrator_password        = "H@Sh1CoR3!"
  sku_name   = "GP_Standard_D2s_v3"
  version                       = "12"
}