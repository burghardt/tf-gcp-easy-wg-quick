#!/usr/bin/env bash
set -x
set -euo pipefail
IFS=$'\n\t'

ufw allow ssh
ufw enable

ua status --wait
sudo ua refresh

snap refresh

apt update
apt -y upgrade
apt -y install git iptables unattended-upgrades \
               wireguard-tools mawk grep iproute2 qrencode
apt -y autoremove
apt autoclean

tee /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

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

mkdir -p /root/easy-wg-quick
pushd /root/easy-wg-quick
    echo ufw > fwtype.txt
    echo 443 > portno.txt
    ip route sh | awk '$1 == "default" && $2 == "via" { print $5; exit }' > extnetif.txt
    curl -4 ifconfig.co/ip > extnetip.txt

    docker run --rm -v "$PWD:/pwd" ghcr.io/burghardt/easy-wg-quick

    cp wghub.conf /etc/wireguard/wghub.conf
popd

systemctl enable wg-quick@wghub
systemctl start wg-quick@wghub
