ifeq ($(PACKAGE_SET),dom0)
RPM_SPEC_FILES := rpm_spec/xen-hvm-stubdom-linux.spec
endif

include $(ORIG_SRC)/Makefile.vars

INCLUDED_SOURCES = \
	qemu-$(QEMU_VERSION).tar.xz \
	linux-$(LINUX_VERSION).tar.xz \
	busybox-$(BUSYBOX_VERSION).tar.bz2 \
	pulseaudio-$(PULSEAUDIO_VERSION).tar.xz

ifneq ($(filter $(DISTRIBUTION), fedora centos opensuse),)
SOURCE_COPY_IN := $(INCLUDED_SOURCES)
endif

$(INCLUDED_SOURCES): PACKAGE=$@
$(INCLUDED_SOURCES):
	cp $(ORIG_SRC)/dl/$(PACKAGE) $(CHROOT_DIR)$(DIST_SRC)

# Enable repo for special GCC with plugin support
ifneq ($(filter $(DISTRIBUTION), opensuse),)
MOCK_EXTRA_OPTS += --enablerepo=obs-gcc
YUM_OPTS += --enablerepo=obs-gcc
endif