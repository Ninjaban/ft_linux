#!/usr/bin/env bash

doMake()
{
	make
	make check
	make install
}

doOpen()
{
	name=$1
	version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
	echo "Install ${name}${version}..."
	tar -xf ${name}${version}.tar*
	cd ${name}${version}
}

doClose()
{
	echo "Finalize ${name}${version}..."
	cd $LFS/sources/
	rm -rf ${name}${version}
}

install_packet()
{
	doOpen $1

	./configure --prefix=/usr
	doMake

	doClose
}

install_gdbm()
{
	doOpen "gdbm-"

	./configure --prefix=/usr \
	            --disable-static \
    	        --enable-libgdbm-compat

	doMake

	doClose
}

install_gperf()
{
	doOpen "gperf-"

	./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
	doMake

	doClose
}

install_expat()
{
	doOpen "expat-"

	sed -i 's|usr/bin/env |bin/|' run.sh.in

	./configure --prefix=/usr --disable-static
	doMake

	install -v -dm755 /usr/share/doc/expat-2.2.3
	install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.3

	doClose
}

install_inetutils()
{
	doOpen "inetutils-"

	./configure --prefix=/usr        \
	            --localstatedir=/var \
	            --disable-logger     \
	            --disable-whois      \
	            --disable-rcp        \
	            --disable-rexec      \
	            --disable-rlogin     \
	            --disable-rsh        \
	            --disable-servers

	doMake

	mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
	mv -v /usr/bin/ifconfig /sbin

	doClose
}

install_perl()
{
	doOpen "perl-"

	echo "127.0.0.1 localhost $(hostname)" > /etc/hosts

	export BUILD_ZLIB=False
	export BUILD_BZIP2=0

	sh Configure -des -Dprefix=/usr                 \
	                  -Dvendorprefix=/usr           \
	                  -Dman1dir=/usr/share/man/man1 \
	                  -Dman3dir=/usr/share/man/man3 \
	                  -Dpager="/usr/bin/less -isR"  \
	                  -Duseshrplib                  \
	                  -Dusethreads

	make
	make -k test
	make install
	unset BUILD_ZLIB BUILD_BZIP2

	doClose
}

install_xmlparser()
{
	doOpen "XML-Parser-"

	perl Makefile.PL

	doMake

	doClose
}

install_intltool()
{
	doOpen "intltool-"

	sed -i 's:\\\${:\\\$\\{:' intltool-update.in

	./configure --prefix=/usr

	doMake
	install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

	doClose
}

install_automake()
{
	doOpen "automake-"

	./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.15.1

	make
	sed -i "s:./configure:LEXLIB=/usr/lib/libfl.a &:" t/lex-{clean,depend}-cxx.sh
	make -j4 check
	make install

	doClose
}

install_xz()
{
	doOpen "xz-"

	./configure --prefix=/usr    \
	            --disable-static \
	            --docdir=/usr/share/doc/xz-5.2.3

	doMake
	mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
	mv -v /usr/lib/liblzma.so.* /lib
	ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so

	doClose
}

install_kmod()
{
	doOpen "kmod-"

	./configure --prefix=/usr          \
	            --bindir=/bin          \
	            --sysconfdir=/etc      \
	            --with-rootlibdir=/lib \
	            --with-xz              \
	            --with-zlib

	make
	make install

	for target in depmod insmod lsmod modinfo modprobe rmmod; do
	  ln -sfv ../bin/kmod /sbin/$target
	done

	ln -sfv kmod /bin/lsmod

	doClose
}

install_gettext()
{
	doOpen "gettext-"

	sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
	sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in

	./configure --prefix=/usr    \
	            --disable-static \
	            --docdir=/usr/share/doc/gettext-0.19.8.1

	doMake
	chmod -v 0755 /usr/lib/preloadable_libintl.so

	doClose
}

install_procpsng()
{
	doOpen "procps-ng-"

	./configure --prefix=/usr                            \
	            --exec-prefix=                           \
	            --libdir=/usr/lib                        \
	            --docdir=/usr/share/doc/procps-ng-3.3.12 \
	            --disable-static                         \
	            --disable-kill

	make
	sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
	sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
	rm testsuite/pgrep.test/pgrep.exp
	make check
	make install

	mv -v /usr/lib/libprocps.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so

	doClose
}

install_e2fsprogs()
{
	doOpen "e2fsprogs-"

	mkdir -v build
	cd build

	LIBS=-L/tools/lib                    \
	CFLAGS=-I/tools/include              \
	PKG_CONFIG_PATH=/tools/lib/pkgconfig \
	../configure --prefix=/usr           \
	             --bindir=/bin           \
	             --with-root-prefix=""   \
	             --enable-elf-shlibs     \
	             --disable-libblkid      \
	             --disable-libuuid       \
	             --disable-uuidd         \
	             --disable-fsck

	make
	ln -sfv /tools/lib/lib{blk,uu}id.so.1 lib
	make LD_LIBRARY_PATH=/tools/lib check

	make install
	make install-libs

	chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
	gunzip -v /usr/share/info/libext2fs.info.gz
	install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

	makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
	install -v -m644 doc/com_err.info /usr/share/info
	install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

	doClose
}

install_coreutils()
{
	doOpen "coreutils-"

	patch -Np1 -i ../coreutils-8.27-i18n-1.patch
	sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk

	FORCE_UNSAFE_CONFIGURE=1 ./configure \
	            --prefix=/usr            \
	            --enable-no-install-program=kill,uptime

	FORCE_UNSAFE_CONFIGURE=1 make

	make NON_ROOT_USERNAME=nobody check-root
	echo "dummy:x:1000:nobody" >> /etc/group
	chown -Rv nobody .

	sed -i '/dummy/d' /etc/group

	make install

	mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
	mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
	mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
	mv -v /usr/bin/chroot /usr/sbin
	mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
	sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8

	mv -v /usr/bin/{head,sleep,nice,test,[} /bin

	doClose
}

install_findutils()
{
	doOpen "findutils-"

	sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in
	./configure --prefix=/usr --localstatedir=/var/lib/locate

	doMake

	mv -v /usr/bin/find /bin
	sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb

	doClose
}

install_groff()
{
	doOpen "groff-"

	PAGE=A4 ./configure --prefix=/usr

	make
	make install

	doClose
}

install_grub()
{
	doOpen "grub-"

	./configure --prefix=/usr          \
            	--sbindir=/sbin        \
            	--sysconfdir=/etc      \
            	--disable-efiemu       \
            	--disable-werror

	make
	make install

	doClose
}

install_less()
{
	doOpen "less-"

	./configure --prefix=/usr --sysconfdir=/etc

	make
	make install

	doClose
}

install_gzip()
{
	doOpen "gzip-"

	./configure --prefix=/usr

	doMake
	mv -v /usr/bin/gzip /bin

	doClose
}

install_iproute2()
{
	doOpen "iproute2-"

	sed -i /ARPD/d Makefile
	sed -i 's/arpd.8//' man/man8/Makefile
	rm -v doc/arpd.sgml

	sed -i 's/m_ipt.o//' tc/Makefile

	make
	make DOCDIR=/usr/share/doc/iproute2-4.12.0 install

	doClose
}

install_kbd()
{
	doOpen "kbd-"

	patch -Np1 -i ../kbd-2.0.4-backspace-1.patch

	sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
	sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

	PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock

	doMake

	mkdir -v       /usr/share/doc/kbd-2.0.4
	cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.4

	doClose
}

install_libpipeline()
{
	doOpen "libpipeline-"

	PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr
	doMake

	doClose
}

install_make()
{
	doOpen "make-"

	./configure --prefix=/usr

	make
	make PERL5LIB=$PWD/tests/ check
	make install

	doClose
}

install_sysklogd()
{
	doOpen "sysklogd-"

	sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
	sed -i 's/union wait/int/' syslogd.c

	make
	make BINDIR=/sbin install

	cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF

	doClose
}

install_sysvinit()
{
	doOpen "sysvinit-"

	patch -Np1 -i ../sysvinit-2.88dsf-consolidated-1.patch

	make -C src
	make -C src install

	doClose
}

install_eudev()
{
	doOpen "eudev-"

	sed -r -i 's|/usr(/bin/test)|\1|' test/udev-test.pl
	sed -i '/keyboard_lookup_key/d' src/udev/udev-builtin-keyboard.c

	cat > config.cache << "EOF"
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include"
EOF

	./configure --prefix=/usr           \
	            --bindir=/sbin          \
	            --sbindir=/sbin         \
	            --libdir=/usr/lib       \
	            --sysconfdir=/etc       \
	            --libexecdir=/lib       \
	            --with-rootprefix=      \
	            --with-rootlibdir=/lib  \
	            --enable-manpages       \
	            --disable-static        \
	            --config-cache

	LIBRARY_PATH=/tools/lib make

	mkdir -pv /lib/udev/rules.d
	mkdir -pv /etc/udev/rules.d

	make LD_LIBRARY_PATH=/tools/lib check
	make LD_LIBRARY_PATH=/tools/lib install

	tar -xvf ../udev-lfs-20140408.tar.bz2
	make -f udev-lfs-20140408/Makefile.lfs install

	LD_LIBRARY_PATH=/tools/lib udevadm hwdb --update

	doClose
}

install_utillinux()
{
	doOpen "util-linux-"

	mkdir -pv /var/lib/hwclock

	./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
	            --docdir=/usr/share/doc/util-linux-2.30.1 \
	            --disable-chfn-chsh  \
	            --disable-login      \
	            --disable-nologin    \
	            --disable-su         \
	            --disable-setpriv    \
	            --disable-runuser    \
	            --disable-pylibmount \
	            --disable-static     \
	            --without-python     \
	            --without-systemd    \
	            --without-systemdsystemunitdir

	make
	chown -Rv nobody .

	make install

	doClose
}

install_mandb()
{
	doOpen "man-db-"

	./configure --prefix=/usr                        \
	            --docdir=/usr/share/doc/man-db-2.7.6.1 \
	            --sysconfdir=/etc                    \
	            --disable-setuid                     \
	            --enable-cache-owner=bin             \
	            --with-browser=/usr/bin/lynx         \
	            --with-vgrind=/usr/bin/vgrind        \
	            --with-grap=/usr/bin/grap            \
	            --with-systemdtmpfilesdir=

	doMake

	doClose
}

install_tar()
{
	doOpen "tar-"

	FORCE_UNSAFE_CONFIGURE=1  \
	./configure --prefix=/usr \
	            --bindir=/bin

	doMake

	make -C doc install-html docdir=/usr/share/doc/tar-1.29

	doClose
}

install_tar()
{
	doOpen "tar-"

	./configure --prefix=/usr --disable-static

	doMake

	make TEXMF=/usr/share/texmf install-tex

	pushd /usr/share/info
	rm -v dir
	for f in *
	  do install-info $f dir 2>/dev/null
	done
	popd

	doClose
}

install_vim()
{
	doOpen "vim-"

	echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

	sed -i '/call/{s/split/xsplit/;s/303/492/}' src/testdir/test_recover.vim

	./configure --prefix=/usr
	make
	make test &> vim-test.log
	make install

	ln -sv vim /usr/bin/vi
	for L in  /usr/share/man/{,*/}man1/vim.1; do
	    ln -sv vim.1 $(dirname $L)/vi.1
	done

	ln -sv ../vim/vim80/doc /usr/share/doc/vim-8.0.586

	cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2
set mouse=r
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif


" End /etc/vimrc
EOF

	touch ~/.vimrc

	doClose
}

sysfile_launch()
{
	echo "install libtool..." && install_packet "libtool-" && read
	echo "install gdbm..." && install_gdbm && read
	echo "install gperf..." && install_gperf && read
	echo "install expat..." && install_expat && read
	echo "install inetutils..." && install_inetutils && read
	echo "install perl..." && install_perl && read
	echo "install XML-Parser..." && install_xmlparser && read
	echo "install intltool..." && install_intltool && read
	echo "install autoconf..." && install_packet "autoconf-" && read
	echo "install automake..." && install_automake && read
	echo "install xz..." && install_xz && read
	echo "install kmod..." && install_kmod && read
	echo "install gettext..." && install_gettext && read
	echo "install procpsng..." && install_procpsng && read
	echo "install e2fsprogs..." && install_e2fsprogs && read
	echo "install coreutils..." && install_coreutils && read
	echo "install diffutils..." && install_packet "diffutils-" && read
	echo "install gawk..." && install_packet "gawk-" && read
	echo "install findutils..." && install_findutils && read
	echo "install groff..." && install_groff && read
	echo "install grub..." && install_grub && read
	echo "install less..." && install_less && read
	echo "install gzip..." && install_gzip && read
	echo "install iproute2..." && install_iproute2 && read
	echo "install kdb..." && install_kbd && read
	echo "install libpipeline..." && install_libpipeline && read
	echo "install make..." && install_make && read
	echo "install patch..." && install_packet "patch-" && read
	echo "install sysklogd..." && install_sysklogd && read
	echo "install sysvinit..." && install_sysvinit && read
	echo "install eudev..." && install_eudev && read
	echo "install utillinux..." && install_utillinux && read
	echo "install mandb..." && install_mandb && read
	echo "install tar..." && install_tar && read
	echo "install vim..." && install_vim && read
}

sysfile_launch
