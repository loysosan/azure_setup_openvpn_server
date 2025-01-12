module "vm-openvpn" {
  source                = "./modules/virtual_machine_openvpn"
  resource_group_name   = var.resource_group_name
  location              = var.location
  vm_name               = var.vm_name
  vm_size               = var.vm_size_openvpn
  admin_username        = var.admin_username_vm
  ssh_public_key        = var.ssh_public_key
  custom_data_path      = "./custom_scsript/vm_openvpn_init.tpl"
  vpn_domain_name       = "vpn.openvpnazuresertver.com"
}
