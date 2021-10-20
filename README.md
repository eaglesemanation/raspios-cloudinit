# raspios-cloudinit

Packer configuration for building RaspiOS Lite image with Cloud-Init and Netplan included for first-boot provisioning


## Building from scratch

### Dependencies

#### Fedora

Run `sudo dnf install make podman podman-docker qemu-user-static`

#### Other

You are on your own, open PR if you want to add support for other platform
- `docker` or `podman`
- `make`
- `qemu-user-static`


### Build

1. Make any needed changes in `./config` for cloud-init
2. Run `sudo make img WIFI_COUNTRY=US` replacing "US" with [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements)
   code of country in which Raspberry Pi will operate
3. Resulting image will be put into `./output` directory

### Flashing

Makefile includes simple script to flash and verify built image

1. Run `lsblk -do name,model,tran,size` to find name of SD Card, it should have an "usb" transfer type
2. **CAREFULLY** (this can overwrite data on any device) run `sudo make flash SD_CARD=/dev/sd*` where "/dev/sd*" is a name from previous step
