# raspios-cloudinit

Packer configuration for building RaspiOS Lite image with Cloud-Init and
Netplan included for first-boot provisioning

## Building from scratch

### Dependencies

#### Fedora

1. Add Hashicorp repository to install packer:
```bash
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
```

1. Install packer and ansible:
```bash
sudo dnf install packer ansible-core ansible-collection-community-general
```

#### Other

You are on your own, open PR if you want to add support for other platform
- `packer`
- `ansible-core`
- `ansible-collection-community-general`

### Build

1.  Make any changes in `group_vars/all.yml` for image settings

1.  Make any needed changes in `./config` for cloud-init

1.  Run `sudo packer build -var arch=arm64 .`
(You can replace arch with `armhf` for 32bit version).
Resulting image will be put into `./output` directory

### Flashing

Makefile includes simple script to flash and verify built image

1.  Run `make lsblk` to find name of SD Card, it should
have an "usb" transfer type

1.  **CAREFULLY** (this can overwrite data on any device) run
`sudo make flash SD_CARD=/dev/sd*` where "/dev/sd*" is a name from previous step
