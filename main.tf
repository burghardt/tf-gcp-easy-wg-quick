provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  zone        = var.zone
  region      = var.region
}

resource "google_compute_network" "wghub_network" {
  name = "wghub-network"
}

resource "google_compute_firewall" "iap_firewall" {
  name          = "allow-ssh-from-iap"
  network       = google_compute_network.wghub_network.name
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "wghub_firewall" {
  name          = "allow-wg-from-anywhere"
  network       = google_compute_network.wghub_network.name
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
    ports    = ["443"]
  }
}

data "google_compute_image" "wghub_instance_image" {
  family  = var.wghub_instance_image_family
  project = var.wghub_instance_image_project
}

resource "google_service_account" "wghub_instance_account" {
  account_id   = "wghub-instance-account-id"
  display_name = "wghub-instance-service-account"
}

resource "google_project_iam_binding" "wghub_instance_account_iam" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])
  role    = each.key
  project = var.project
  members = ["serviceAccount:${google_service_account.wghub_instance_account.email}"]
}

resource "google_compute_instance" "wghub_instance" {
  name         = "wghub-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.wghub_instance_image.self_link
    }
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  metadata_startup_script = file("instance-startup.bash")

  network_interface {
    network = google_compute_network.wghub_network.name
    access_config {
    }
  }

  service_account {
    email  = google_service_account.wghub_instance_account.email
    scopes = ["cloud-platform"]
  }

  tags = ["wghub"]
}

resource "null_resource" "client_qrcode" {
  triggers = {
    id = google_compute_instance.wghub_instance.id
  }
  provisioner "local-exec" {
    command = "echo 'allow 180 seconds for boot-up' ; sleep 180"
  }
  provisioner "local-exec" {
    command     = "systemctl is-system-running --wait >/dev/null 2>&1 ; sudo cat /var/local/easy-wg-quick/wgclient_10.qrcode.txt"
    interpreter = ["gcloud", "compute", "ssh", "--tunnel-through-iap", "--zone", "${var.zone}", "${google_compute_instance.wghub_instance.name}", "--command"]
  }
  depends_on = [google_compute_instance.wghub_instance]
}
