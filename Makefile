TOP := $(dir $(firstword $(MAKEFILE_LIST)))

CONTAINER_CLI  ?= docker
BUILDER_IMAGE  ?= ghcr.io/solo-io/packer-plugin-arm-image/packer-builder-arm:v0.2.1
BUILDER_CONFIG ?= $(TOP)/rpi-cloudinit-image.pkr.hcl

CACHE_DIR  ?= $(TOP)/cache
OUTPUT_DIR ?= $(TOP)/output
IMAGE_ARCH ?= armhf

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

help:	## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

img:	## Builds modified image. Add IMAGE_ARCH=arm64 to build 64 bit version
	@mkdir -p $(CACHE_DIR) $(OUTPUT_DIR)
	@:$(call check_defined, WIFI_COUNTRY, add WIFI_COUNTRY=** \(for example us\) to command)
	@:$(if $(shell echo $(IMAGE_ARCH) | grep -E '^arm(hf|64)$$'),, $(error Supported architectures: armhf, arm64))
	$(CONTAINER_CLI) run \
		--rm -it \
		--privileged \
		-v /dev:/dev \
		-v $(BUILDER_CONFIG):/build/packer-config.pkr.hcl:ro \
		-v $(TOP)/config:/build/config:ro \
		-v $(TOP)/templates:/build/templates:ro \
		-v $(CACHE_DIR):/build/packer_cache \
		-v $(OUTPUT_DIR):/build/output-raspios_lite \
		$(BUILDER_IMAGE) build \
		-var arch=$(IMAGE_ARCH) -var wifi_country=$(WIFI_COUNTRY)\
		packer-config.pkr.hcl
	@mv -f $(OUTPUT_DIR)/image $(OUTPUT_DIR)/rpi-$(IMAGE_ARCH).img

flash:	## Flash image to path defined in SD_CARD variable. Requires root access
	@:$(call check_defined, SD_CARD, add SD_CARD=/dev/sd* to command)
	@:$(if $(shell lsblk -do tran $(SD_CARD) | grep 'usb'),, $(error SD_CARD doesn't seem to be an USB device))
	dd if=./output/rpi-$(IMAGE_ARCH).img of=$(SD_CARD) conv=fsync bs=8M status=progress
	cmp -n $(shell stat -c '%s' ./output/rpi-$(IMAGE_ARCH).img) ./output/rpi-$(IMAGE_ARCH).img $(SD_CARD)
	@echo '$(shell tput setaf 2)Flashing finished!$(shell tput sgr0)'
