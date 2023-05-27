#!/bin/bash

LATEST_RELEASE="https://api.github.com/repos/supermerill/superslicer/releases"

if [[ -v $STY ]] || [[ -z $STY ]]; then
  echo -e '\033[1;36m**** The SuperSlicer build process can take a long time. Screen or an alternative is advised for long-running terminal sessions. ****\033[0m'
fi

BUILD_AARCH64=""
BUILD_ARMHF=""

# determine build parameters
case $1 in
  "aarch64")
    BUILD_AARCH64="yes"
    unset BUILD_ARMHF
  ;;
  "armhf")
    BUILD_ARMHF="yes"
    unset BUILD_AARCH64
  ;;
  "all")
    BUILD_AARCH64="yes"
    BUILD_ARMHF="yes"
  ;;
  *)
    echo "Options: [ aarch64 | armhf | all ] [ automated ]"
    echo "Example: $0 aarch64 automated"
    exit 1
  ;;
esac

if [[ $2 == "automated" ]]; then
  AUTO="yes"
fi

# detect platform architecture
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

# get the latest superslicer version
LATEST_VERSION="$(curl -SsL ${LATEST_RELEASE} | jq -r 'first | .tag_name')"

if [[ -v AUTO ]]; then
  REPLY=""
else
  read -p "The latest version appears to be: ${LATEST_VERSION} .. Would you like to enter a different version (like a git tag or a commit? Or continue (leave blank)? " -r
fi

if [[ "${REPLY}" != "" ]]; then
  echo
  echo "Version will be set to ${REPLY}"
  LATEST_VERSION="${REPLY}"
else
  echo "Building with version retrieved from the API: ${LATEST_VERSION}"
fi

if [[ -z "${LATEST_VERSION}" ]]; then

  echo "Could not determine the latest version."
  echo
  echo "Possible reasons for this error:"
  echo "* Has release naming changed from previous conventions?"
  echo "* Are curl and jq installed and working as expected?"
  echo "${LATEST_VERSION}"
  exit 1
else
  echo "I'll be building SuperSlicer using ${LATEST_VERSION}"
fi

# detect container runtime
if hash podman; then
  echo "Detected Podman container runtime under ${DPKG_ARCH} .."
  RUNTIME="podman"
elif hash docker; then
  echo "Detected Docker container runtime under ${DPKG_ARCH} .."
  RUNTIME="docker"
else 
  echo "Please install podman or docker container tooling on this system to proceed."
  exit 1
fi

if [[ -v BUILD_AARCH64 ]]; then
  ${RUNTIME} build -t superslicer-builder .
fi

if [[ -v BUILD_ARMHF ]]; then
  # Build superslicer-builder-armhf at the same time
  cp Dockerfile Dockerfile.armhf
  sed -i 's@raspberrypi4-64@raspberrypi3@g' Dockerfile.armhf
  ${RUNTIME} build -t superslicer-builder-armhf -f Dockerfile.armhf .
fi

if [[ ! -d "superslicer" ]]; then
  git clone https://github.com/supermerill/superslicer

fi

if [[ -v BUILD_AARCH64 ]]; then

cd superslicer || exit
git checkout "${LATEST_VERSION}"

{ time ${RUNTIME} run --device /dev/fuse --cap-add SYS_ADMIN -v "${PWD}:/superslicer:z" -i superslicer-builder bash -- <<EOF
./BuildLinux.sh -u  && \
./BuildLinux.sh -ds && \
sed -i "s@x86_64@${APPIMAGE_ARCH}@g" ./build/build_appimage.sh && \
./BuildLinux.sh -i
EOF
} |& sed -e 's/^/aarch64> /;' |& tee superslicer-aarch64-build.log &

cd ..

fi

if [[ -v BUILD_ARMHF ]]; then

if [[ ! -d "superslicer-armhf" ]]; then
  git clone https://github.com/supermerill/superslicer superslicer-armhf
fi

cd superslicer-armhf || exit
git checkout "${LATEST_VERSION}"

{ time setarch -B linux32 ${RUNTIME} run --device /dev/fuse --cap-add SYS_ADMIN -v "${PWD}:/superslicer:z" -i superslicer-builder-armhf bash -- <<EOF
./BuildLinux.sh -u  && \
./BuildLinux.sh -ds && \
sed -i "s@x86_64@armhf@g" ./build/build_appimage.sh && \
./BuildLinux.sh -i
EOF
} |& sed -e 's/^/armhf> /;' |& tee superslicer-armhf-build.log &

cd ..

fi

jobs
wait
