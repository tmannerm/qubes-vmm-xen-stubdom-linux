#!/bin/bash

set -e
umask 022

script_qemu_ifup="extra/qemu-ifup"
script_init="extra/initscript"

XEN_ROOT="$(cd ..; pwd)"
xenstore_libs="$XEN_ROOT/tools/xenstore"
libxc_libs="$XEN_ROOT/tools/libxc"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$xenstore_libs"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$libxc_libs"

initdir="`pwd`/initramfs/"

rm -fr "$initdir"

# Using dracut to gather the shared libraries
# from https://dracut.wiki.kernel.org/index.php/Main_Page
if ! test -x "$DRACUT_INSTALL"; then
  echo DRACUT_INSTALL unset or incorrect >&2
  exit 1
fi
if ! test -x "$GENEXT2FS"; then
  if ! which genext2fs 2>&1 >/dev/null; then
    echo genext2fs not found and GENEXT2FS unset >&2
    exit 1
  fi
else
  function genext2fs(){
    "$GENEXT2FS" "$@"
  }
fi


inst() {
    [[ -e "${initdir}/${2:-$1}" ]] && return 0  # already there
    "$DRACUT_INSTALL" -D "$initdir" -l "$@"
}

mkdir -p "$initdir"/{bin,etc,proc/xen,sys,lib,dev,tmp}

echo "Building initrd in $initdir"
inst busybox /bin/busybox
make DESTDIR="$initdir" -C qemu-build install
# this gather libs install on the system for qemu
inst "$initdir/bin/qemu-system-i386" /bin/qemu
inst "$XEN_ROOT/tools/xenstore/xenstore-read" "/bin/xenstore-read"
inst "$script_qemu_ifup" "/etc/qemu-ifup"
chmod +x "$initdir/etc/qemu-ifup"
inst "$script_init" "/init"
chmod 755 "$initdir/init"

ln -s busybox "$initdir/bin/mount"

for d in "/usr/lib" "$xenstore_libs" "$libxc_libs"; do
  d="$initdir/$d"
  if test -d "$d"; then
    mv "$d"/* "$initdir/lib64/"
    if test -L "$d"; then
      rm "$d"
    else
      rmdir --ignore-fail-on-non-empty -p "$d"
    fi
  fi
done

mv "$initdir/lib64/gcc"/*/*/* "$initdir/lib64/"
rm -rf "$initdir/lib64/gcc"

mkdir -p "$initdir/usr"
ln -s /lib "$initdir/usr/lib"

if false; then
  IMAGE="./initramfs.cpio"
  rm -f "$IMAGE"
  (cd "$initdir"; find . | cpio -H newc --quiet -o) >| "$IMAGE" || exit 1
  gzip -f "$IMAGE"
else # ext2 fs using:
  stubdom_disk=stubdom-disk.img
  rm -f "$stubdom_disk"
  genext2fs \
    --root "$initdir" \
    --size-in-blocks $(($(du -s "$initdir"|cut -f1)+2000)) \
    --reserved-percentage 0 \
    --squash \
    "$stubdom_disk"
fi
