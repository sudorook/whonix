#! /bin/bash
set -euo pipefail

function get_whonix_info {
  curl "${WHONIX_URL}" |
    sed -n '/.*href="https:\/\/download.whonix.org\/libvirt\/.*.libvirt.xz.*/{s/.*href="\(.*\.libvirt.xz\)".*/\1/p}' |
    head -n 1
}

WHONIX_URL="https://www.whonix.org/wiki/KVM"
DOWNLOAD_URL="$(get_whonix_info)"
WHONIX_VERSION="$(echo "${DOWNLOAD_URL}" | cut -d "/" -f 5)"
WHONIX_ARCHIVE="$(echo "${DOWNLOAD_URL}" | cut -d "/" -f 6)"

LIBVIRT_DIR=${HOME}/.local/libvirt/images

mkdir -p "${LIBVIRT_DIR}"
pushd "${LIBVIRT_DIR}" > /dev/null

curl -L# "${DOWNLOAD_URL}" -o "${WHONIX_ARCHIVE}"

tar xf "${WHONIX_ARCHIVE}"
sync

rm WHONIX_BINARY_LICENSE_AGREEMENT WHONIX_DISCLAIMER

mv -vf \
  Whonix-Gateway-Xfce-"${WHONIX_VERSION}".Intel_AMD64.qcow2 \
  Whonix-Gateway.qcow2
mv -vf \
  Whonix-Workstation-Xfce-"${WHONIX_VERSION}".Intel_AMD64.qcow2 \
  Whonix-Workstation.qcow2
mv -vf \
  Whonix-Gateway-Xfce-"${WHONIX_VERSION}".xml \
  Whonix-Gateway-Xfce.xml
mv -vf \
  Whonix-Workstation-Xfce-"${WHONIX_VERSION}".xml \
  Whonix-Workstation-Xfce.xml
mv -vf \
  Whonix_external_network-"${WHONIX_VERSION}".xml \
  Whonix_external_network.xml
mv -vf \
  Whonix_internal_network-"${WHONIX_VERSION}".xml \
  Whonix_internal_network.xml

sed -i "s,/var/lib/libvirt/images,${LIBVIRT_DIR},g" Whonix-Gateway-Xfce.xml
sed -i "s,/var/lib/libvirt/images,${LIBVIRT_DIR},g" Whonix-Workstation-Xfce.xml

virsh -c qemu:///system net-define Whonix_external_network.xml
virsh -c qemu:///system net-define Whonix_internal_network.xml
virsh -c qemu:///system net-autostart Whonix-External
virsh -c qemu:///system net-autostart Whonix-Internal
virsh -c qemu:///system net-start Whonix-External
virsh -c qemu:///system net-start Whonix-Internal

virsh -c qemu:///system define Whonix-Gateway-Xfce.xml
virsh -c qemu:///system define Whonix-Workstation-Xfce.xml

rm -vf "${WHONIX_ARCHIVE}"
rm -vf Whonix_external_network.xml
rm -vf Whonix_internal_network.xml
rm -vf Whonix-Gateway-Xfce.xml
rm -vf Whonix-Workstation-Xfce.xml

pushd > /dev/null
