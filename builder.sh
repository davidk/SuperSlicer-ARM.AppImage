#!/bin/bash

DPKG_ARCH="$(dpkg --print-architecture)"

if [[ "${DPKG_ARCH}" == "armhf" ]]; then
  APPIMAGE_ARCH="armhf"
elif [[ "${DPKG_ARCH}" == "arm64" ]]; then
  APPIMAGE_ARCH="aarch64"
else
  echo "Unknown architecture [arch: ${DPKG_ARCH}]."
  echo "Please update the build assistant to add support."
  exit 1
fi

podman build -t superslicer-builder .

if [[ ! -d "superslicer" ]]; then
  git clone https://github.com/supermerill/superslicer
fi

cd superslicer

podman run --device /dev/fuse --cap-add SYS_ADMIN -v $PWD:/superslicer:z -i superslicer-builder sh -- <<EOF 
./BuildLinux.sh -u 
./BuildLinux.sh -ds

./BuildLinux.sh -u 
sed -i "s@x86_64@${APPIMAGE_ARCH}@g" ./build/build_appimage.sh 
./BuildLinux.sh -i
EOF

readlink -f ./superslicer/build/SuperSlicer_ubu64.AppImage
