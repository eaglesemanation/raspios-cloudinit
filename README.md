# raspios-cloudinit

Packer configuration for building RaspiOS Lite image with Cloud-Init and
Netplan included for first-boot provisioning

## Using release version

1. Open [latest release](https://github.com/eaglesemanation/raspios-cloudinit/releases/latest) and download an image with required architecture.

1. (Optional) Download file with `.sha256` extension and run `sha256sum --check raspios-cloudinit*.zip.sha256` to verify that downloaded image is intact.

1. Extract `.img` file from downloaded zip.

1. Run `lsblk -pdo name,tran,size,label` to find path to SD card that you intend for use. 
It should be simular to `/dev/sda` and have `usb` transfer type.

1. **CAREFUL!** (this step can overwrite data on any device)
Run `dd if={Extracted .img file} of={Path from previous step} conv=fsync bs=8M status=progress` replacing parts of command in curly braces.

1. (Optional) Run `cmp -n $(stat -c '%s' {.img file}) {.img file} {path to sd card}` to verify that image was written successfully.

## Building from scratch

### Dependencies

#### Ubuntu

1. Add Hashicorp keys and repository to install packer:
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
```

1. Add Ansible PPA for newest release
```bash
sudo add-apt-repository --yes --update ppa:ansible/ansible
```

1. Install packer and ansible:
```bash
sudo apt-get update
sudo apt-get install -y packer ansible
```

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

1.  Make any changes in `group_vars/all.yml` for image settings.

1.  Make any needed changes in `./config` for cloud-init.

1.  Run `sudo packer build -var arch=arm64 .`
(You can replace arch with `armhf` for 32bit version).
Resulting image will be put into `./output-raspios-cloudinit` directory.

### Flashing

Makefile includes simple script to flash and verify built image.

1.  Run `make lsblk` to find name of SD Card, it should
have an "usb" transfer type.

1.  **CAREFUL!** (this step can overwrite data on any device) run
`sudo make flash SD_CARD=/dev/sd*` where "/dev/sd*" is a name from previous step
