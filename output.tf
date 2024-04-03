output "project" {
  value = var.project
}

output "zone" {
  value = var.zone
}

output "wghub_public_ip" {
  value = google_compute_instance.wghub_instance.network_interface[0].access_config[0].nat_ip
}

output "qrcode_retrieval_command" {
  value = "gcloud compute ssh --tunnel-through-iap --zone ${var.zone} ${google_compute_instance.wghub_instance.name} --command 'sudo cat /root/easy-wg-quick/wgclient_10.qrcode.txt'"
}

output "interactive_shell_command" {
  value = "gcloud compute ssh --tunnel-through-iap --zone ${var.zone} ${google_compute_instance.wghub_instance.name}"
}

output "gcloud_set_project" {
  value = "gcloud config set project ${var.project}"
}
