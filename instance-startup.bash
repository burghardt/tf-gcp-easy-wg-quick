#!/usr/bin/env bash
set -x
set -euo pipefail
IFS=$'\n\t'

ua status --wait
sudo ua refresh

snap refresh

apt update
apt -y upgrade
apt -y install git iptables unattended-upgrades \
               wireguard-tools mawk grep iproute2 qrencode
apt -y autoremove
apt autoclean

tee /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
};

Unattended-Upgrade::Package-Blacklist {
};
EOF

tee /etc/apt/apt.conf.d/60unattended-reboot << 'EOF'
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:30";
EOF

pushd /var/local
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install
popd

git clone https://github.com/burghardt/easy-wg-quick.git \
    /var/local/easy-wg-quick

pushd /var/local/easy-wg-quick
    echo 443 > portno.txt
    curl ifconfig.co/ip > extnetip.txt

    ./easy-wg-quick

    cp wghub.conf /etc/wireguard/wghub.conf
popd

systemctl enable wg-quick@wghub
systemctl start wg-quick@wghub
