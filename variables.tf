# ============================================================================
# This project is fully independent from the VNet project
# (azure-virtual-network). It does NOT read that project's state - instead,
# the network details it needs (resource group, location, subnet) are passed
# in explicitly as variables below.
#
# Get these values from the VNet project's outputs after a `terraform apply`
# there, e.g.:
#   terraform output -raw resource_group_name
#   terraform output -raw app_subnet_id
#
# Or look them up directly in the Azure Portal / via az cli:
#   az network vnet subnet list \
#     --resource-group rg-network --vnet-name vnet-ha --output table
# ============================================================================

variable "subscription_id" {
  description = "Azure subscription ID - required explicitly by azurerm >= 4.0. No default on purpose: pass it via -var, a gitignored .tfvars, or the TF_VAR_subscription_id environment variable"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the EXISTING resource group where the VNet lives (from the network project)"
  type        = string
  default     = "rg-network"
}

variable "location" {
  description = "Azure region - must match the existing VNet's region"
  type        = string
  default     = "centralus"
}

variable "app_subnet_id" {
  description = "Full resource ID of the existing App subnet to deploy the management VM into. Get this from the network project's `app_subnet_id` output."
  type        = string
}

variable "mgmt_vm_size" {
  description = "VM size for the isolated management VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "mgmt_admin_username" {
  description = "Admin username for the management VM"
  type        = string
  default     = "azureuser"
}

variable "mgmt_zone" {
  description = "Availability zone to pin the management VM to. The App subnet itself spans all zones (subnets aren't zonal in Azure) - this only affects the VM's own placement"
  type        = string
  default     = "1"
}

variable "tags" {
  description = "Common tags applied to resources in this project"
  type        = map(string)
  default = {
    environment = "production"
    project     = "mgmt-jumpbox"
    managed_by  = "terraform"
  }
}
