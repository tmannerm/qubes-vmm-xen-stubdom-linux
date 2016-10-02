XEN_ROOT = $(CURDIR)/..

-include $(XEN_ROOT)/config/Tools.mk
include $(XEN_ROOT)/Config.mk

# Qemu tree used
QEMU_TREE=git://xenbits.xen.org/qemu-upstream-4.5-testing.git
QEMU_BRANCH=qemu-xen-4.5.0

all:

qemu-build/Makefile:
	export GIT=$(GIT); \
	$(XEN_ROOT)/scripts/git-checkout.sh $(QEMU_TREE) $(QEMU_BRANCH) qemu-remote
	cd qemu-remote && patch -p1 < ../qemu-configure.patch
	cd qemu-remote && patch -p1 < ../qemu-xen-common.patch
	cd qemu-remote && patch -p1 < ../qemu-xen-h.patch
	cd qemu-remote && patch -p1 < ../qemu-xen-hvm.patch
	mkdir -p qemu-build
	cd qemu-build && ../qemu-remote/configure \
		--target-list=i386-softmmu \
		--enable-xen \
		--extra-cflags="-I$(XEN_ROOT)/tools/include \
			-I$(XEN_ROOT)/tools/libxc \
			-I$(XEN_ROOT)/tools/xenstore \
			-I$(XEN_ROOT)/tools/xenstore/compat \
			-DDEBUG_XEN" \
		--extra-ldflags="-L$(XEN_ROOT)/tools/libxc -L$(XEN_ROOT)/tools/xenstore" \
		--disable-werror \
		--disable-sdl \
		--disable-kvm \
		--disable-gtk \
		--disable-fdt \
		--disable-bluez \
		--disable-libusb \
		--disable-slirp \
		--disable-pie \
		--disable-docs \
		--disable-vhost-net \
		--disable-spice \
		--disable-guest-agent \
		--audio-drv-list= \
		--disable-smartcard-nss \
		--enable-stubdom \
		--disable-vnc \
		--disable-spice \
		--enable-trace-backend=stderr \
		--disable-curses \
		--python=$(PYTHON) \
		--prefix=

.PHONY:qemu-build
qemu-build: qemu-build/Makefile
qemu-build/i386-softmmu/qemu-system-i386: qemu-build
	$(MAKE) -C qemu-build
