variable vnet_rg {}

variable security_rg {}

variable "palo_fileshare_directories" {
  default = "config"
}
variable "palo_fileshare_directories1" {
  default = "content"
}
variable "palo_fileshare_directories2" {
  default = "software"
}
variable "palo_fileshare_directories3" {
  default = "license"
}

variable "bootstrap_store_name" {}



variable in_fw_bootstrap_file_share {
  description = "Storage account's file share name that contains the bootstrap directories"
  default = "in-fw-fs"
}

variable out_fw_bootstrap_file_share {
  description = "Storage account's file share name that contains the bootstrap directories"
   default = "out-fw-fs"
}
variable dev-environment {
  default = "dev"
}
variable build-version {}
