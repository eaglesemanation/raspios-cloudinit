packer {
  required_plugins {
    arm-image = {
      version = ">= 0.2.5"
      source  = "github.com/solo-io/arm-image"
    }
  }
}

variable "arch" {
  type = string

  validation {
    condition     = can(regex("arm(hf|64)", var.arch))
    error_message = "Supported architectures are: armhf, arm64."
  }
}

variable "raspios_url" {
  type    = map(string)
  default = {
    armhf = "https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-11-08/2021-10-30-raspios-bullseye-armhf-lite.zip"
    arm64 = "https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2021-11-08/2021-10-30-raspios-bullseye-arm64-lite.zip"
  }
}

variable "raspios_checksum" {
  type    = map(string)
  default = {
    armhf = "008d7377b8c8b853a6663448a3f7688ba98e2805949127a1d9e8859ff96ee1a9"
    arm64 = "c88109027eac44b9ff37a7f3eb1873cdf6d7ca61a0264ec0e95870ca96afd242"
  }
}

# Arch dependent base image
locals {
  image_url      = lookup(var.raspios_url, var.arch, "")
  image_checksum = "sha256:${lookup(var.raspios_checksum, var.arch, "")}"

  qemu_binary = lookup({
    armhf = "qemu-arm-static"
    arm64 = "qemu-aarch64-static"
  }, var.arch, "qemu-arm-static")

  mount_path = "/tmp/raspios-cloudinit"
}

source "arm-image" "raspios-cloudinit" {
  target_image_size = 4294967296
  iso_checksum      = local.image_checksum
  iso_url           = local.image_url
  qemu_binary       = local.qemu_binary
  mount_path        = local.mount_path
}

build {
  sources = ["arm-image.raspios-cloudinit"]

  provisioner "ansible" {
    extra_arguments  = [
      "--connection=chroot",
      "-e", "ansible_host='${ local.mount_path }' arch='${ var.arch }'"
    ]
    ansible_env_vars = ["ANSIBLE_NOCOWS=1"]

    playbook_file = "./site.yml"
  }
}
