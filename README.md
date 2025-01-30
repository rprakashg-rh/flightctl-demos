# flightctl-demos
This repository contains all the artifacts used in flightctl demos

## Installing FlightCTL

## Building RHDE starter app
This is a sample containerized application that we want to deploy to device. Application will be installed on device as podman quadlet

```sh

```


## Building image (Early binding)

```sh
podman build -t imagemode-rhel -f images/device/Containerfile .
```
Tag the image with registry

```sh
podman tag imagemode-rhel quay.io/rgopinat/imagemode-rhel
```

### Building Anaconda ISO using Bootc Image Builder


```sh
    sudo podman run --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v $(pwd)/images/device/config.toml:/config.toml -v $(pwd)/output:/output \
    registry.redhat.io/rhel9/bootc-image-builder:latest \
    --type iso \
    --config /config.toml \
    quay.io/rgopinat/imagemode-rhel:latest
```
