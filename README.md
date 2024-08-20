# tf-gcp-easy-wg-quick
Terraform configuration for deploying [easy-wg-quick] in Google Cloud Platform

## Getting Started

These instructions will get you a copy of the project up and running on your
Google Cloud Platform account.

### Prerequisites

Installed and configured [gcloud] and [terraform] tools are required to deploy
this project in your infrastructure.

### Installing

Clone repository.

    git clone https://github.com/burghardt/tf-gcp-easy-wg-quick.git

## Usage

Login to your GCP account, when [running Terraform on your workstation] use
command below.

    gcloud auth application-default login

Set JSON credentials file name and GCP project name in the `terraform.tfvars`
file.

    project          = "gcp-project-name"
    credentials_file = "~/.config/gcloud/application_default_credentials.json"

Then follow the typical Terraform command sequence to deploy `easy-wg-quick`
to the cloud.

    terraform init
    terraform validate
    terraform plan
    terraform apply

When the deployment is ready `local-exec` of `gcloud` will dump the QR code
to the console. Scan it with the mobile Wireguard application. Outputs also
contain examples of `gcloud` commands to access the wghub instance.

## Fine tuning

### Region, zone, boot image

The region, zone, and boot image are customizable with variables. Keep in mind
that [instance-startup.bash] script assumes recent releases of Debian/Ubuntu
with Wireguard available for APT. If switching to another distribution,
adjust this script accordingly.

### Adding more clients

To add more clients or configure `easy-wg-quick` parameters modify [instance-startup.bash] script. Refer to [easy-wg-quick] documentation for details.

### SSH access to wghub instance

Direct access to port 22 from the Internet is disabled by design. So instead,
use [IAP] tunneling to access wghub securely.

    gcloud compute ssh --tunnel-through-iap ...

### Accessing easy-wg-quick data

Script data is available on wghub instance in the `/root/easy-wg-quick`
directory.

## License

This project is licensed under the MPL-2.0 License - see the [LICENSE] file
for details.

[easy-wg-quick]: https://github.com/burghardt/easy-wg-quick
[gcloud]: https://cloud.google.com/sdk/docs/install
[running Terraform on your workstation]: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#running-terraform-on-your-workstation
[terraform]: https://learn.hashicorp.com/tutorials/terraform/install-cli
[instance-startup.bash]: instance-startup.bash
[IAP]: https://cloud.google.com/iap/
[LICENSE]: LICENSE
