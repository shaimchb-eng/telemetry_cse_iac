# Define a variable for the Azure Active Directory tenant ID
# This uniquely identifies your Azure AD tenant. We have already filled this in for you.
variable "tenant_id" { 
 type = string 
 default = "60a5e6b0-6783-462c-a4a4-08c0cd9c5706" 
} 

# Define a variable for the Azure subscription ID
# This identifies which subscription Terraform will deploy resources into.
# You can find it in the Azure portal under "Subscriptions" > "Subscription ID". Details below.
variable "subscription_id" { 
 type = string 
 default = "4dbffbb6-92ea-4699-bba4-5c52b58301ff"
} #TO BE FILLED  

# Define a variable for the resource group name associated with your personal sandbox.
# A resource group is a container that holds related Azure resources.
variable "rg_name" { 
 type = string 
 default = "sandbox_chaimae.chahab" 
} #TO BE FILLED 

# Define a variable for the Azure region (location) where resources will be deployed.
variable "location" { 
 type  = string 
 default = "France Central"
} 