# containerd

```bash
cd busybox
mkdir rootfs
docker export $(docker create busybox) | tar -C rootfs -xvf -

```

## supervision tech

```bash
http://smarden.org/runit/

```