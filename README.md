# flightctl-demos
This repository contains all the artifacts used in flightctl demos

## Installing FlightCTL

## Building RHDE starter app
This is a sample containerized application that we want to deploy to device. Application will be installed on device as podman quadlet

```sh
podman build -t rhde-starter .
```
Tag the image

```sh
podman tag rhde-starter quay.io/rgopinat/rhde-starter
```

Push the image

```sh
podman push quay.io/rgopinat/rhde-starter
```


### Building image (Early binding)

```sh
podman build -t imagemode-rhel -f images/device/Containerfile .
```
Tag the image with registry

```sh
podman tag imagemode-rhel quay.io/rgopinat/imagemode-rhel
```

### Building Anaconda ISO using Bootc Image Builder
Follow steps below to build an Anaconda ISO installer image

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

Copy the ISO file to local to build a bootable disk

```

```


### Building Imagemode RHEL with FDO (Late binding)

#### Build container

```sh
podman build -t imagemode-rhel-fdo -f images/fdo_device/Containerfile .
```

#### Tag container with registry
```sh
podman tag imagemode-rhel-fdo quay.io/rgopinat/imagemode-rhel-fdo
```

#### Push container image to registry

```sh
podman push quay.io/rgopinat/imagemode-rhel-fdo
```

### Build anaconda ISO with bootc image builder 

```sh
    sudo podman run --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v $(pwd)/images/fdo_device/config.toml:/config.toml -v $(pwd)/output:/output \
    registry.redhat.io/rhel9/bootc-image-builder:latest \
    --type iso \
    --config /config.toml \
    quay.io/rgopinat/imagemode-rhel-fdo:latest
```
