# Backend remoto en Azure Blob Storage, gestionado por el proyecto
# azure-tfstate-bootstrap. El storage account y el container ya existen
# (no los gestiona este módulo). El locking es nativo vía blob lease.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatejohanaks"
    container_name       = "tfstate"
    key                  = "jumpbox/terraform.tfstate"
  }
}
