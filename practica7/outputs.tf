output "hostname" {
  value = var.hostname
}

output "private_key" {
  value = module.bastion.private_key
}
output "ssh_command" {
  value = module.bastion.ssh_command
}
