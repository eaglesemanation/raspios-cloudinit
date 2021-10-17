variable "arch" {
  type    = string
  default = "armhf"
}

variable "wifi_country" {
  type    = string
}

# Arch dependent base image
locals {
  raspios_checksum = lookup({
    armhf = "sha256:c5dad159a2775c687e9281b1a0e586f7471690ae28f2f2282c90e7d59f64273c"
    arm64 = "sha256:868cca691a75e4280c878eb6944d95e9789fa5f4bbce2c84060d4c39d057a042"
  }, var.arch, "")
  raspios_url      = "https://downloads.raspberrypi.org/raspios_lite_${var.arch}/images/raspios_lite_${var.arch}-2021-05-28/2021-05-07-raspios-buster-${var.arch}-lite.zip"
  qemu_binary      = lookup({
    armhf = "qemu-arm-static"
    arm64 = "qemu-aarch64-static"
  }, var.arch, "qemu-arm-static")
}

source "arm-image" "raspios_lite" {
  target_image_size = 4294967296
  iso_checksum      = local.raspios_checksum
  iso_url           = local.raspios_url
  qemu_binary       = local.qemu_binary
}

build {
  sources = ["arm-image.raspios_lite"]

  # Keep packages up to date
  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y"
    ]
  }

  # Replace Debian network management with netplan + NetworkManager + systemd-resolved
  provisioner "shell" {
    inline = [
      "apt-get --autoremove purge -y %{ if var.arch == "armhf" } dhcpcd %{ endif } dhcpcd5",
      "apt-mark hold avahi-daemon %{ if var.arch == "armhf" } dhcpcd %{ endif } dhcpcd5 openresolv",
      "apt-get install -y cloud-init netplan.io network-manager",
      "ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf",
      "systemctl enable NetworkManager.service systemd-resolved.service systemd-networkd.service"
    ]
  }

  # Enables mDNS globally and disables DNSSEC
  # DNSSEC causes NTP to hang, because certificates are "expired" due to incorrect date
  provisioner "file" {
    source      = "templates/resolved.conf"
    destination = "/etc/systemd/resolved.conf"
  }

  # Configures systemd to keep network devices names
  provisioner "file" {
    source      = "templates/99-keep-names.link"
    destination = "/etc/systemd/network/99-keep-names.link"
  }

  # Configure NetworkManager to search for connection files in /run instead of /etc
  # because netplan decided to do so
  provisioner "file" {
    source      = "templates/NetworkManager.conf"
    destination = "/etc/NetworkManager/NetworkManager.conf"
  }

  # Makes systemd-networkd wait for NetworkManager to initialize
  provisioner "shell" {
    inline = ["mkdir -p /etc/systemd/system/NetworkManager.service.d/"]
  }
  provisioner "file" {
    source      = "templates/NetworkManager-service-override.conf"
    destination = "/etc/systemd/system/NetworkManager.service.d/override.conf"
  }
  provisioner "shell" {
    inline = ["chmod 644 /etc/systemd/system/NetworkManager.service.d/override.conf"]
  }

  # Configures cloud-init to search for configs in /boot
  provisioner "file" {
    source      = "templates/cloud.cfg"
    destination = "/etc/cloud/cloud.cfg"
  }

  # Enables WiFi
  provisioner "shell" {
    inline = [
      "echo 'country=${var.wifi_country}' >> /etc/wpa_supplicant/wpa_supplicant.conf",
      "echo 0 > /var/lib/systemd/rfkill/platform-3f300000.mmcnr:wlan",
      "echo 0 > /var/lib/systemd/rfkill/platform-fe300000.mmcnr:wlan"
    ]
  }

  # Enables sshd
  provisioner "shell" {
    inline = [
      "systemctl enable ssh"
    ]
  }

  # Generates random instance-id
  provisioner "shell" {
    inline = [ "echo 'instance-id: ${uuidv4()}' > /boot/meta-data" ]
  }

  provisioner "file" {
    source      = "config/user-data.yaml"
    destination = "/boot/user-data"
  }

  provisioner "file" {
    source      = "config/network-config.yaml"
    destination = "/boot/network-config"
  }

}
