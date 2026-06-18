locals {
  # AZ the diagram currently has tenant compute running in.
  tenant_az = var.availability_zones[var.tenant_subnet_az_index]
}
