# SuperSlicer-ARM.AppImage

This is a ARM builder for SuperMerill's SuperSlicer. It is currently intended for testing purposes; AppImages will not be regularly built and released.

# Using 

1. Acquire a container runtime. `podman` was used to test and construct this builder.

2. Run `build.sh` to build the image in Dockerfile, tag it as `superslicer-builder` and build either the latest upstream version, or a specified one. This will take about an hour on a Radxa Rock 5B with 16GB of RAM and NVMe storage.

3. When complete, the AppImage will appear in `./superslicer/build/`, with the naming: `./superslicer/build/SuperSlicer_$VERSION-$ARCH.AppImage`. Ex: `./superslicer/build/SuperSlicer_2.5.59.2-arm64.AppImage` is output based on building SuperSlicer version 2.5.59.2 for arm64 systems.

# Running

Using the AppImage found above, run the AppImage in a terminal `./superslicer/build/SuperSlicer_$VERSION-$ARCH.AppImage`. Or execute it from a file manager.

# Builder notes

When `all` is passed to `build.sh` it will attempt to build both armhf and aarch64 at the same time (concurrently). This may cause a build to fail on a system with low resources. To avoid this, run the builder with each desired architecture(s) specified in a sequential manner.
