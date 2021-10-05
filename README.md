# Infrastructure for muralovka.ru

This repository contains all code needed to setup muralovka.ru infrastructure


## Prerequisites

### Dependencies

#### Fedora

Run `sudo dnf install make podman podman-docker`

#### Other

You are on your own, open PR if you want to add support for other platform
- `docker` or `podman`
- `make`

### Cloning repository

1. Open terminal somewhere where it will be easy to find files later, like `~/Documents`
2. Run `git clone https://github.com/eaglesemanation/muralovka-infra.git && cd muralovka-infra`


## Deployment

### 1. Flashing configured image to RPi

Skip to step 6 if image is already prebuilt

1. Go to `./rpi-clooudinit-image`
2. In `config/user-data.yml` you may want to change `hostname`, `timezone` (check for available options by running `timedatectl list-timezones`), and 2 fields for user with name `ansible`: `ssh_authorized_keys` and `passwd`
3. In `config/network-config.yml` you can set Ethernet config to have static IP, or enable WiFi. By default it will use DHCP on Ethernet
4. Run `sudo make img WIFI_COUNTRY=ru`. It may fail after unzipping image for the first time, try multiple times until you see it run updates. It will finish with message `Build 'arm-image' finished.`
5. Backup `output/rpi-*.img` for future use
6. Run `lsblk -do name,model,tran,size` to find name of SD Card, it should have an "usb" transfer type
7. **CAREFULLY** (this can overwrite data on any device) run `sudo make flash SD_CARD=/dev/sd*` where "/dev/sd*" is a name from previous step
