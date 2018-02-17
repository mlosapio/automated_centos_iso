
WGET ?= wget
CENTOS_NETINSTALL ?= http://mirror.es.its.nyu.edu/centos/7/isos/x86_64/CentOS-7-x86_64-NetInstall-1708.iso
CENTOS_FULLPATH ?= $(shell basename $(CENTOS_NETINSTALL))
KS_LOCATION ?= http://mike.losap.io/ks.cfg

UNAME_S ?= $(shell uname)

.PHONY: build
build: download
	if [ ! -d ./bootiso ]; then mkdir ./bootiso; fi
	if [ ! -d ./customiso ]; then mkdir ./customiso; fi
ifeq ($(UNAME_S),Darwin)
	hdiutil attach -nomount $(CENTOS_FULLPATH)
	mount -t cd9660 /dev/disk2 ./bootiso
endif
ifneq ($(UNAME_S),Darwin)
	echo "Only OSX builds supported at this time"
	exit 1
endif
	rsync -avz ./bootiso/* ./customiso/
	umount ./bootiso
	rmdir ./bootiso
	sed -i '' 's|timeout 600|timeout 1|' ./customiso/isolinux/isolinux.cfg
	sed -i '' '/menu default/d' ./customiso/isolinux/isolinux.cfg
	sed -i '' 's|menu label ^Install CentOS 7$$|menu label ^Install CentOS 7\'$$'\n  menu default|' ./customiso/isolinux/isolinux.cfg
	sed -i '' 's|append initrd=initrd.img inst|append initrd=initrd.img ks=http://mike.losap.io/ks.cfg inst|' ./customiso/isolinux/isolinux.cfg
	cd ./customiso && mkisofs -o ../boot.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -V "CentOS 7 x86_64" -R -J -v -T isolinux/. .
	#chmod -

.PHONY: check
check:
	@type mkisofs >/dev/null 2>&1 || echo "Please install mkisofs\nOSX: brew install cdrtools"

.PHONY: download
download: check
	if [ ! -f $(CENTOS_FULLPATH) ]; then $(WGET) $(CENTOS_NETINSTALL); fi

.PHONY: clean
clean:
	rm -rf ./bootiso
	rm -rf ./customiso


distclean: clean
	rm *.iso
