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
  type = map(string)

  validation {
    condition     = lookup(var.raspios_url, "armhf", "") != ""
    error_message = "URL for armhf should be specified."
  }
  validation {
    condition     = lookup(var.raspios_url, "arm64", "") != ""
    error_message = "URL for arm64 should be specified."
  }
}

variable "raspios_checksum" {
  type = map(string)

  validation {
    condition     = lookup(var.raspios_checksum, "armhf", "") != ""
    error_message = "SHA256 for armhf should be specified."
  }
  validation {
    condition     = lookup(var.raspios_checksum, "arm64", "") != ""
    error_message = "SHA256 for arm64 should be specified."
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
