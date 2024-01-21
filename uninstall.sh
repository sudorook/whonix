#! /bin/bash
set -eu

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
