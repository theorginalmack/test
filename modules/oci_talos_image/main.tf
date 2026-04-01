data "oci_objectstorage_namespace" "default_namespace" {}

resource "oci_objectstorage_bucket" "images_bucket" {
  compartment_id = var.compartment_id
  name           = var.images_bucket
  namespace      = data.oci_objectstorage_namespace.default_namespace.namespace
  storage_tier   = "Standard"
}

resource "oci_objectstorage_object" "talos_image_archive" {
  bucket    = oci_objectstorage_bucket.images_bucket.name
  namespace = data.oci_objectstorage_namespace.default_namespace.namespace
  object    = "oracle-arm64.oci"
  source    = var.image_file
}

resource "oci_core_image" "talos_arm64" {
  compartment_id = oci_objectstorage_bucket.images_bucket.compartment_id
  display_name   = "Talos ARM64"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    bucket_name              = oci_objectstorage_bucket.images_bucket.name
    namespace_name           = data.oci_objectstorage_namespace.default_namespace.namespace
    object_name              = oci_objectstorage_object.talos_image_archive.object
    operating_system         = "Talos Linux"
    operating_system_version = var.talos_version
    source_image_type        = "QCOW2"
    source_type              = "objectStorageTuple"
  }

  timeouts {
    create = "30m"
  }
}
