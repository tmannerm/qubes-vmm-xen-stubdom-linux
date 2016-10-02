XEN_ROOT = $(CURDIR)/..

-include $(XEN_ROOT)/config/Tools.mk
include $(XEN_ROOT)/Config.mk

# Qemu tree used
QEMU_TREE=git://xenbits.xen.org/qemu-upstream-4.5-testing.git
QEMU_BRANCH=qemu-xen-4.5.0

# Linux Kernel version used
LINUX_V=linux-3.17.8
VMLINUZ=$(LINUX_V)/arch/x86/boot/bzImage
LINUX_URL=ftp://ftp.kernel.org/pub/linux/kernel/v3.x/$(LINUX_V).tar.xz

all: $(VMLINUZ)

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

$(LINUX_V).tar.xz:
	$(FETCHER) $@ $(LINUX_URL)

$(LINUX_V)/Makefile $(LINUX_V)/.config: $(LINUX_V).tar.xz
	rm -rf $(LINUX_V)
	tar xf $(LINUX_V).tar.xz
	# Temp patches
	patch -d $(LINUX_V) -p1 -i ../0002-fix-remap_area_mfn_pte_fn.patch
	patch -d $(LINUX_V) -p1 -i ../0001-hvc_xen-Don-t-write-in-the-type-node-in-xenstore.patch
	cp stubdom-linux-config-64b $(LINUX_V)/.config

$(VMLINUZ): $(LINUX_V)/.config
	$(MAKE) -C $(LINUX_V)

install: $(VMLINUZ)
	cp -f $(VMLINUZ) $(DESTDIR)/usr/local/lib/xen/boot/vmlinuz-stubdom
