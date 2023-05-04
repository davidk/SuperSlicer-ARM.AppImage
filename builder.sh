#!/bin/bash

podman build -t superslicer-builder .

if [[ ! -d "superslicer" ]]; then
  git clone https://github.com/supermerill/superslicer
fi

cd superslicer
podman run -v $PWD:/superslicer:z -it superslicer-builder ./BuildLinux.sh -u && ./BuildLinux.sh -ds

# todo: generate appimage, arch dependent
