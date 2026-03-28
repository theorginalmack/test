data "oci_objectstorage_namespace" "default_namespace" {
  compartment_id = var.compartment_id
}

data "oci_objectstorage_bucket" "images_bucket" {
  name      = var.images_bucket
  namespace = data.oci_objectstorage_namespace.default_namespace.namespace
}

resource "oci_core_image" "talos_arm64" {
  compartment_id = data.oci_objectstorage_bucket.images_bucket.compartment_id
  display_name   = "Talos ARM64"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    bucket_name              = data.oci_objectstorage_bucket.images_bucket.name
    namespace_name           = data.oci_objectstorage_bucket.images_bucket.namespace
    object_name              = "oracle-arm64.oci"
    operating_system         = "Talos Linux"
    operating_system_version = "1.12.2"
    source_image_type        = "QCOW2"
    source_type              = "objectStorageTuple"
  }

  timeouts {
    create = "30m"
  }
}
