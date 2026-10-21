#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
images=/var/lib/libvirt/images
iso=$images/Win11_25H2.iso
disk=$images/win11.qcow2
xml=$here/../hosts/homeserver/vm/win11.xml

if [ "$(id -u)" -ne 0 ]; then
  echo "run as root" >&2
  exit 1
fi

if [ ! -f "$iso" ]; then
  echo "missing ISO: $iso" >&2
  exit 1
fi

if ! virsh net-info default >/dev/null 2>&1; then
  virsh net-define "$here/libvirt-default-network.xml"
fi
virsh net-start default 2>/dev/null || true
virsh net-autostart default >/dev/null

if [ ! -f "$disk" ]; then
  qemu-img create -f qcow2 "$disk" 80G
fi

virsh define "$xml"
echo "defined. start with: virsh start win11"
