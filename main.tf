resource "google_project_service" "filestore" {
  project = var.project_id
  service = "file.googleapis.com"
}

resource "google_filestore_instance" "filestore" {
  name     = "test-instance"
  location = "us-central1-b"
  tier     = "BASIC_HDD"

  file_shares {
    name        = "cloudroot_share"
    capacity_gb = 1024

    nfs_export_options {
      ip_ranges   = ["0.0.0.0/0"]
      access_mode = "READ_WRITE"
      squash_mode = "NO_ROOT_SQUASH"
    }
  }

  networks {
    network      = "default"
    modes        = ["MODE_IPV4"]
    connect_mode = "DIRECT_PEERING"
  }
  depends_on = [google_project_service.filestore]
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

locals {
  filestore_ip               = google_filestore_instance.filestore.networks[0].ip_addresses
  filestore_single_ip_string = join("", local.filestore_ip)
}


data "template_file" "client_userdata_script" {
  template = file("${path.root}/start_script.tpl")
  vars = {
    filestore_ip = local.filestore_single_ip_string
  }
}

resource "google_compute_instance" "vm_instance" {
  count        = 1
  name         = "vm-instance-${count.index}"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  metadata_startup_script = data.template_file.client_userdata_script.rendered

  depends_on = [google_project_service.filestore, google_filestore_instance.filestore]
}