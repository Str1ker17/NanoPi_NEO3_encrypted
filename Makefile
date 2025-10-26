.PHONY: help obtain backup flash clean

SHELL := sh -x
DD := dd status=none conv=sync,fsync,fdatasync
PARTITION := /dev/mmcblk1p7
INPUT ?= p7_boot.img

help:
	@echo Help?

obtain:
	@$(DD) if=$(PARTITION) of=p7_boot.img

p7_boot.img.size: $(INPUT)
	@$(DD) if=$< bs=1 skip=4 count=4 | od --address-radix=n --endian=little --format=u4 --read-bytes=4 | tr -d ' ' > $@

p7_boot.cpio.gz: $(INPUT) p7_boot.img.size
	@$(DD) if=$< of=$@ iflag=skip_bytes,count_bytes skip=8 count=$$(cat $(word 2,$^))

# Does not work for a reason.
#p7_boot.img.crc: $(INPUT) p7_boot.img.size p7_boot.cpio.gz
#	@$(DD) if=$< iflag=skip_bytes,count_bytes skip=$$(expr $$(cat $(word 2,$^)) + 8) count=4 | od --address-radix=n --endian=little --format=x4 --read-bytes=4 | tr -d ' ' > $@
#	@crc32 $(word 1,$^) | diff - $@

p7_boot.cpio: p7_boot.cpio.gz
	@gzip -d -c -n -k $< > $@

extract: p7_boot.cpio
	@sudo rm -rf ./$@
	# Work around the `cpio' bug with --directory and without --no-change-owner.
	@mkdir -p $@/$@
	@cat $< | sudo cpio --directory=$@ --extract --make-directories --preserve-modification-time --no-absolute-filenames --quiet --unconditional --no-preserve-owner
	@rmdir $@/$@

p7_boot_re.cpio: cryptsetup-initramfs
	@sudo rsync -av --chmod=+x cryptsetup-initramfs/ extract/
	@cd extract && sudo find . -print0 | sudo cpio --create --null --format=newc --owner=0:0 | cat > ../$@

p7_boot_re.cpio.gz: p7_boot_re.cpio
	@cat $< | gzip -c -n -1 > $@

p7_boot_re.img: p7_boot_re.cpio.gz
	@gzip -t $<
	@printf "KRNL" > $@
	@stat --format="%s" $< | perl -e 'print pack("V", <>)' >> $@
	@cat $< >> $@

backup:
	@sudo $(DD) if=$(PARTITION) of=p7_boot.backup.img conv=fsync

flash: p7_boot_re.img backup
	@sudo $(DD) if=$< of=$(PARTITION) conv=fsync
	@sudo blockdev --flushbufs $(PARTITION)

clean:
	@rm -rf p7_boot.img.size p7_boot.cpio.gz p7_boot.img.crc p7_boot.cpio p7_boot_re.cpio p7_boot_re.cpio.gz p7_boot_re.img
