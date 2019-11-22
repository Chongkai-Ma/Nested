#!/bin/bash

cpuModule=$1

/usr/libexec/qemu-kvm -M q35 -cpu $cpuModule,svm  -enable-kvm -m 6144 -smp 4   \
-name nested-L1 \
-device pcie-root-port,id=pcie.0-root-port-2,slot=2,chassis=2,addr=0x2,bus=pcie.0 \
-device pcie-root-port,id=pcie.0-root-port-3,slot=3,chassis=3,addr=0x3,bus=pcie.0 \
-device pcie-root-port,id=pcie.0-root-port-4,slot=4,chassis=4,addr=0x4,bus=pcie.0 \
-device pcie-root-port,id=pcie.0-root-port-5,slot=5,chassis=5,addr=0x5,bus=pcie.0 \
-device virtio-scsi-pci,id=scsi0,bus=pcie.0-root-port-2,addr=0x0 \
-object secret,id=sec0,data=redhat \
-blockdev driver=file,cache.direct=off,cache.no-flush=on,filename=/home/nested-autoshell/nested.luks,node-name=protocol-node \
-blockdev node-name=format-node,driver=luks,file=protocol-node,key-secret=sec0 \
-device scsi-hd,bus=scsi0.0,drive=format-node \
-device virtio-net-pci,mac=52:54:69:b5:35:15,id=netdev1,vectors=4,netdev=net1,bus=pcie.0-root-port-3 -netdev tap,id=net1,vhost=on,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown \
-nographic  \
-vnc :1  -vga qxl   

#-kernel  /home/nested-autoshell/vmlinuz  \
#-initrd  /home/nested-autoshell/initrd.img \
#-append  method="$url  inst.text console=tty0 console=ttyS0,115200 "
