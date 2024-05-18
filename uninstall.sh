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

set -eu

ROOT="$(dirname "${0}")"

source "${ROOT}"/globals

! check_command grep virsh && exit 3

LIBVIRT_DIR=${HOME}/.local/libvirt/images

mkdir -p "${LIBVIRT_DIR}"
pushd "${LIBVIRT_DIR}" > /dev/null

if grep -q Whonix-Gateway <(virsh -c qemu:///system list --state-running); then
  virsh -c qemu:///system destroy Whonix-Gateway
fi
virsh -c qemu:///system undefine Whonix-Gateway

if grep -q Whonix-Workstation <(virsh -c qemu:///system list --state-running); then
  virsh -c qemu:///system destroy Whonix-Workstation
fi
virsh -c qemu:///system undefine Whonix-Workstation

virsh -c qemu:///system net-destroy Whonix-External
virsh -c qemu:///system net-undefine Whonix-External
virsh -c qemu:///system net-destroy Whonix-Internal
virsh -c qemu:///system net-undefine Whonix-Internal

rm -vf Whonix-Gateway.qcow2
rm -vf Whonix-Workstation.qcow2

popd > /dev/null
