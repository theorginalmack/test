provider "oci" {
  fingerprint  = var.fingerprint
  private_key  = base64decode(var.private_key)
  region       = var.region
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
}