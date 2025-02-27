resource "google_filestore_instance" "example" {
  name     = "test-instance"
  location = "us-central1-b"
  tier     = "BASIC_HDD"

  file_shares {
    name        = "example-share"
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
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}


resource "google_compute_instance" "vm_instance" {
  count        = 2
  name         = "vm-instance-${count.index}"
  machine_type = "e2-medium"

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

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nfs-common
    sudo mkdir -p /mnt/filestore
    sudo mount -o nolock ${google_filestore_instance.example.networks.0.ip_addresses[0]}:/example-share /mnt/filestore
    echo "${google_filestore_instance.example.networks.0.ip_addresses[0]}:/example-share /mnt/filestore nfs defaults,nolock 0 0" | sudo tee -a /etc/fstab
  EOT
}