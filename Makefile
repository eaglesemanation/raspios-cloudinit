TOP := $(dir $(firstword $(MAKEFILE_LIST)))

OUTPUT_DIR ?= $(TOP)/output-raspios-cloudinit
ARCH ?= armhf

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

help:	## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

img:	## Builds modified image.
	packer build -var 'arch=$(ARCH)' .

lsblk:	## List block devices with additional columns
	lsblk -do name,model,tran,size

flash:	## Flash image to path defined in SD_CARD variable. Requires root access
	@:$(call check_defined, SD_CARD, add SD_CARD=/dev/sd* to command)
	@:$(if $(shell lsblk -do tran $(SD_CARD) | grep 'usb'),, $(error SD_CARD doesn't seem to be an USB device))
	dd if=$(OUTPUT_DIR)/image of=$(SD_CARD) conv=fsync bs=8M status=progress
	cmp -n $(shell stat -c '%s' $(OUTPUT_DIR)/image) $(OUTPUT_DIR)/image $(SD_CARD)
	@echo '$(shell tput setaf 2)Flashing finished!$(shell tput sgr0)'
