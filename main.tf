provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  zone        = var.zone
  region      = var.region
}

resource "google_project_service" "gcp_services" {
  for_each = toset(var.service_list)
  project  = var.project
  service  = each.key

  disable_dependent_services = true
}

resource "google_compute_network" "wghub_network" {
  name                    = "wghub-network"
  auto_create_subnetworks = false

  depends_on = [google_project_service.gcp_services["compute.googleapis.com"]]
}

resource "google_compute_subnetwork" "wghub_subnetwork" {
  name = "wghub-subnetwork"

  ip_cidr_range = "10.0.0.0/29"
  region        = var.region

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"

  network = google_compute_network.wghub_network.name
}

resource "google_compute_firewall" "iap_firewall" {
  name          = "allow-ssh-from-iap"
  network       = google_compute_network.wghub_network.name
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["wghub"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "wghub_ipv4_firewall" {
  name          = "allow-wg-and-icmp-from-anywhere"
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

resource "google_compute_firewall" "wghub_ipv6_firewall" {
  name          = "allow-wg-and-icmpv6-from-anywhere"
  network       = google_compute_network.wghub_network.name
  source_ranges = ["::/0"]

  allow {
    protocol = "58" // ICMPv6
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
  role       = each.key
  project    = var.project
  members    = ["serviceAccount:${google_service_account.wghub_instance_account.email}"]
  depends_on = [google_project_service.gcp_services["iam.googleapis.com"]]
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
    subnetwork = google_compute_subnetwork.wghub_subnetwork.name
    stack_type = "IPV4_IPV6"
    access_config {
    }
    ipv6_access_config {
      network_tier = "PREMIUM"
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
    command = "gcloud config set project ${var.project}"
  }
  provisioner "local-exec" {
    command     = "systemctl is-system-running --wait >/dev/null 2>&1 ; sudo cat /root/easy-wg-quick/wgclient_10.qrcode.txt"
    interpreter = ["gcloud", "compute", "ssh", "--tunnel-through-iap", "--zone", "${var.zone}", "${google_compute_instance.wghub_instance.name}", "--command"]
  }
  depends_on = [google_compute_instance.wghub_instance]
}
