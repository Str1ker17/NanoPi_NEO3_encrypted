# Quickstart

Zeroth, you need an external microSD card. 8Gb is the lower limit, I choose 16Gb.

## First
You need an original image.
This is a gzipped raw disk image with partition table,
can be explored with `sudo losetup -f -P -r rk3328-sd-debian-bookworm-core-6.1-arm64-20250123.img.gz`.

## Second
You need to obtain some binary packages to run crypto on your device.
Some like kernel modules can be taken from `/dev/loop0p8`,
remaining can be downloaded from tracker.debian.org.
Let me list mandatory things:

### LUKS support in the kernel

```
/usr/lib/modules/6.1.63/kernel/drivers/md/dm-crypt.ko
/usr/lib/modules/6.1.63/kernel/security/keys/encrypted-keys/encrypted-keys.ko (dependency of the above)
/usr/lib/modules/6.1.63/modules.* (likely can be reduced)
```

### Utilities & shared libraries

The suffixes may not match 1:1 to the listed.
Please go to tracker.debian.org, choose your distro (Debian 12 for me) and download **binary** packages.

Package list (without suffixes) for ARM64:
```
cryptsetup-bin
libargon2
libcryptsetup12
libjson-c5
libpopt0
libssl3
```

File list, place inside `cryptsetup-initramfs` directory:

```
/usr/lib/aarch64-linux-gnu/libargon2.so    (package libargon2)
/usr/lib/aarch64-linux-gnu/libcryptsetup.so    (package libcryptsetup12)
/usr/lib/aarch64-linux-gnu/libjson-c.so    (package libjson-c5)
/usr/lib/aarch64-linux-gnu/libpopt.so    (package libpopt0)
/usr/lib/aarch64-linux-gnu/libssl.so    (package libssl3)
```

```
/usr/sbin/cryptsetup    (package cryptsetup-bin)
/usr/sbin/integritysetup    (package cryptsetup-bin)
/usr/sbin/veritysetup    (package cryptsetup-bin)
/usr/bin/openssl    (package libssl3)
```

## Third, get original initramfs

If running on image only, it's `/dev/loop0p7`

If running on hardware, it's `/dev/mmcblk1p7`

Copy it with `dd` to `p7_boot.img`

## Fourth, create encrypted partitions

Connect microSD card and run, assume it's /dev/mmcblk1, and on system partition (for userdata it's the same):

```
sudo cryptsetup luksFormat --key-file nvmem --header luks_p8_header.raw --type luks1 /dev/mmcblk1p8
sudo openssl enc -aes-256-ctr -nosalt -pbkdf2 -in luks_p8_header.raw -out luks_p8_header.bin -pass pass:secret_password
```

`nvmem` should be obtained from a running system of a real NanoPi NEO3. If they don't match, decryption will fail.

This is a "protection" from putting miroSD card away from device.

Place `luks_p8_header.bin` into initramfs for auto-decryption.

## Now, ready!

* Re-check that `PARTITION` variable in Makefile is valid
* Run `make` (a good-old C-way) to rebuild and rewrite contents of initramfs partition `/dev/mmcblk1p7`.

# Congratulations?!
