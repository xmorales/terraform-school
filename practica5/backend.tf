terraform {
  backend "azurerm" {
    resource_group_name  = "TerraformState"
    storage_account_name = "terraformschooltid"
    container_name       = "tfstate"
    key                  = "school.terraform.tfstate"
  }
}
