#!/bin/bash

# SPDX-FileCopyrightText: 2024 sudorook <daemon@nullcodon.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

set -euo pipefail

ROOT="$(dirname "${0}")"

source "${ROOT}"/globals

! check_command curl sed virsh && exit 3

function get_whonix_info {
  curl "${WHONIX_URL}" |
    sed -n '/.*href="https:\/\/download.whonix.org\/libvirt\/.*.libvirt.xz.*/{s/.*href="\(.*\.libvirt.xz\)".*/\1/p}' |
    head -n 1
}

function check_all_files {
  local file
  local files=(
    WHONIX_BINARY_LICENSE_AGREEMENT
    WHONIX_DISCLAIMER
    Whonix-Gateway-Xfce-"${WHONIX_VERSION}".Intel_AMD64.qcow2
    Whonix-Workstation-Xfce-"${WHONIX_VERSION}".Intel_AMD64.qcow2
    Whonix-Gateway.xml
    Whonix-Workstation.xml
    Whonix_external_network.xml
    Whonix_internal_network.xml)
  for file in "${files[@]}"; do
    if ! [ -f "${file}" ]; then
      echo "${file@Q} missing. Exiting."
      return 1
    fi
  done
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

if ! check_all_files; then
  exit 3
fi

rm -vf WHONIX_BINARY_LICENSE_AGREEMENT WHONIX_DISCLAIMER

mv -vf \
  Whonix-Gateway-Xfce-"${WHONIX_VERSION}".Intel_AMD64.qcow2 \
  Whonix-Gateway.qcow2
mv -vf \
  Whonix-Workstation-Xfce-"${WHONIX_VERSION}".Intel_AMD64.qcow2 \
  Whonix-Workstation.qcow2

sed -i "s,/var/lib/libvirt/images,${LIBVIRT_DIR},g" Whonix-Gateway.xml
sed -i "s,/var/lib/libvirt/images,${LIBVIRT_DIR},g" Whonix-Workstation.xml

virsh -c qemu:///system net-define Whonix_external_network.xml
virsh -c qemu:///system net-define Whonix_internal_network.xml
virsh -c qemu:///system net-autostart Whonix-External
virsh -c qemu:///system net-autostart Whonix-Internal
virsh -c qemu:///system net-start Whonix-External
virsh -c qemu:///system net-start Whonix-Internal

virsh -c qemu:///system define Whonix-Gateway.xml
virsh -c qemu:///system define Whonix-Workstation.xml

rm -vf "${WHONIX_ARCHIVE}" \
  Whonix_external_network.xml \
  Whonix_internal_network.xml \
  Whonix-Gateway.xml \
  Whonix-Workstation.xml

pushd > /dev/null
