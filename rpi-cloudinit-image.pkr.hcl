packer {
  required_plugins {
    arm-image = {
      version = ">= 0.2.5"
      source  = "github.com/solo-io/arm-image"
    }
  }
}

variable "arch" {
  type    = string

  validation {
    condition     = can(regex("arm(hf|64)", var.arch))
    error_message = "Supported architectures are: armhf, arm64."
  }
}

# Arch dependent base image
locals {
  raspios_checksum = lookup({
    armhf = "sha256:c5dad159a2775c687e9281b1a0e586f7471690ae28f2f2282c90e7d59f64273c"
    arm64 = "sha256:868cca691a75e4280c878eb6944d95e9789fa5f4bbce2c84060d4c39d057a042"
  }, var.arch, "")

  raspios_url = "https://downloads.raspberrypi.org/raspios_lite_${var.arch}/images/raspios_lite_${var.arch}-2021-05-28/2021-05-07-raspios-buster-${var.arch}-lite.zip"

  qemu_binary = lookup({
    armhf = "qemu-arm-static"
    arm64 = "qemu-aarch64-static"
  }, var.arch, "qemu-arm-static")

  mount_path = "/tmp/raspios-cloudinit"
}

source "arm-image" "raspios-cloudinit" {
  target_image_size = 4294967296
  iso_checksum      = local.raspios_checksum
  iso_url           = local.raspios_url
  qemu_binary       = local.qemu_binary
  mount_path        = local.mount_path
}

build {
  sources = ["arm-image.raspios-cloudinit"]

  provisioner "ansible" {
    extra_arguments = [
      "--connection=chroot",
      "-e", "ansible_host='${ local.mount_path }' arch='${ var.arch }'"
    ]

    playbook_file = "./site.yml"
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
