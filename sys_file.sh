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
	cd $LFS/sources/
	rm -rf ${name}${version}
}

install_apiheader()
{
	doOpen "linux-"

	make mrproper

	make INSTALL_HDR_PATH=dest headers_install
	find dest/include \( -name .install -o -name ..install.cmd \) -delete
	cp -rv dest/include/* /usr/include

	doClose
}

install_man_pages()
{
	doOpen "man-pages-"

	make install

	doClose
}

install_glibc()
{
	doOpen "glibc-"

	patch -Np1 -i ../glibc-${version}-fhs-1.patch

	ln -sfv /tools/lib/gcc /usr/lib

	case $(uname -m) in
		i?86)    GCC_INCDIR=/usr/lib/gcc/$(uname -m)-pc-linux-gnu/7.3.0/include
				ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
		;;
		x86_64) GCC_INCDIR=/usr/lib/gcc/x86_64-pc-linux-gnu/7.3.0/include
				ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
				ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
		;;
	esac

	rm -f /usr/include/limits.h

	mkdir -v build
	cd       build

	CC="gcc -isystem $GCC_INCDIR -isystem /usr/include" \
	../configure --prefix=/usr                          \
				 --disable-werror                       \
				 --enable-kernel=3.2                    \
				 --enable-stack-protector=strong        \
				 libc_cv_slibdir=/lib
	unset GCC_INCDIR

	make
	make check

	touch /etc/ld.so.conf
	sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

	make install

	cp -v ../nscd/nscd.conf /etc/nscd.conf
	mkdir -pv /var/cache/nscd

	mkdir -pv /usr/lib/locale
	localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
	localedef -i de_DE -f ISO-8859-1 de_DE
	localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
	localedef -i de_DE -f UTF-8 de_DE.UTF-8
	localedef -i en_GB -f UTF-8 en_GB.UTF-8
	localedef -i en_HK -f ISO-8859-1 en_HK
	localedef -i en_PH -f ISO-8859-1 en_PH
	localedef -i en_US -f ISO-8859-1 en_US
	localedef -i en_US -f UTF-8 en_US.UTF-8
	localedef -i es_MX -f ISO-8859-1 es_MX
	localedef -i fa_IR -f UTF-8 fa_IR
	localedef -i fr_FR -f ISO-8859-1 fr_FR
	localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
	localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
	localedef -i it_IT -f ISO-8859-1 it_IT
	localedef -i it_IT -f UTF-8 it_IT.UTF-8
	localedef -i ja_JP -f EUC-JP ja_JP
	localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
	localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
	localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
	localedef -i zh_CN -f GB18030 zh_CN.GB18030

	make localedata/install-locales

	cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

	tar -xf ../../tzdata2018c.tar.gz

	ZONEINFO=/usr/share/zoneinfo
	mkdir -pv $ZONEINFO/{posix,right}

	for tz in etcetera southamerica northamerica europe africa antarctica  \
			  asia australasia backward pacificnew systemv; do
		zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
		zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
		zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
	done

	cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
	zic -d $ZONEINFO -p America/New_York
	unset ZONEINFO

	cp -v /usr/share/zoneinfo/Europe/Paris /etc/localtime

	cat > /etc/ld.so.conf << "EOF"
# Début de /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

	cat >> /etc/ld.so.conf << "EOF"
# Ajout d'un répertoire include
include /etc/ld.so.conf.d/*.conf

EOF
	mkdir -pv /etc/ld.so.conf.d

	doClose
}

install_zlib()
{
	doOpen "zlib-"

	./configure --prefix=/usr

	doMake

	mv -v /usr/lib/libz.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so

	doClose
}

install_packet()
{
	doOpen $1

	./configure --prefix=/usr
	doMake

	doClose
}

install_readline()
{
	doOpen "readline-"

	sed -i '/MV.*old/d' Makefile.in
	sed -i '/{OLDSUFF}/c:' support/shlib-install

	./configure --prefix=/usr    \
				--disable-static \
				--docdir=/usr/share/doc/readline-${version}

	make SHLIB_LIBS="-L/tools/lib -lncursesw"
	make SHLIB_LIBS="-L/tools/lib -lncurses" install

	mv -v /usr/lib/lib{readline,history}.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
	ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so

	install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-${version}

	doClose
}

install_bc()
{
	doOpen "bc-"

	cat > bc/fix-libmath_h << "EOF"
#! /bin/bash
sed -e '1   s/^/{"/' \
	-e     's/$/",/' \
	-e '2,$ s/^/"/'  \
	-e   '$ d'       \
	-i libmath.h

sed -e '$ s/$/0}/' \
	-i libmath.h
EOF

	ln -sv /tools/lib/libncursesw.so.6 /usr/lib/libncursesw.so.6
	ln -sfv libncurses.so.6 /usr/lib/libncurses.so

	sed -i -e '/flex/s/as_fn_error/: ;; # &/' configure

	./configure --prefix=/usr           \
				--with-readline         \
				--mandir=/usr/share/man \
				--infodir=/usr/share/info

	make
	echo "quit" | ./bc/bc -l Test/checklib.b
	make install

	doClose
}

install_binutils()
{
	doOpen "binutils-"

	expect -c "spawn ls"

	mkdir -v build
	cd       build

	../configure --prefix=/usr       \
				 --enable-gold       \
				 --enable-ld=default \
				 --enable-plugins    \
				 --enable-shared     \
				 --disable-werror    \
				 --with-system-zlib

	make tooldir=/usr
	make -k check
	make tooldir=/usr install

	doClose
}

install_gmp()
{
	doOpen "gmp-"

	./configure --prefix=/usr    \
	            --enable-cxx     \
	            --disable-static \
	            --docdir=/usr/share/doc/gmp-${version}

	make
	make html

	make check 2>&1 | tee gmp-check-log

	awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log

	make install
	make install-html

	doClose
}

install_mpfr()
{
	doOpen "mpfr-"

	./configure --prefix=/usr        \
	            --disable-static     \
	            --enable-thread-safe \
	            --docdir=/usr/share/doc/mpfr-${version}

	make
	make html
	make check
	make install
	make install-html

	doClose
}

install_mpc()
{
	doOpen "mpc-"

	./configure --prefix=/usr    \
	            --disable-static \
	            --docdir=/usr/share/doc/mpc-${version}

	make
	make html
	make check
	make install
	make install-html

	doClose
}

install_gcc()
{
	doOpen "gcc-"

	case $(uname -m) in
	  x86_64)
	    sed -e '/m64=/s/lib64/lib/' \
	        -i.orig gcc/config/i386/t-linux64
	  ;;
	esac

	rm -f /usr/lib/gcc

	mkdir -v build
	cd       build

	SED=sed                               \
	../configure --prefix=/usr            \
	             --enable-languages=c,c++ \
	             --disable-multilib       \
	             --disable-bootstrap      \
	             --with-system-zlib

	make
	ulimit -s 32768
	make -k check
	../contrib/test_summary

	make install
	ln -sv ../usr/bin/cpp /lib
	ln -sv gcc /usr/bin/cc

	install -v -dm755 /usr/lib/bfd-plugins
	ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/${version}/liblto_plugin.so \
	        /usr/lib/bfd-plugins/

	echo 'int main(){}' > dummy.c
	cc dummy.c -v -Wl,--verbose &> dummy.log
	readelf -l a.out | grep ': /lib'

	grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
	grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
	grep "/lib.*/libc.so.6 " dummy.log
	grep found dummy.log
	rm -v dummy.c a.out dummy.log

	mkdir -pv /usr/share/gdb/auto-load/usr/lib
	mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

	doClose
}

install_bzip2()
{
	doOpen "bzip2-"

	patch -Np1 -i ../bzip2-${version}-install_docs-1.patch
	sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
	sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

	make -f Makefile-libbz2_so
	make clean

	make
	make PREFIX=/usr install

	cp -v bzip2-shared /bin/bzip2
	cp -av libbz2.so* /lib
	ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
	rm -v /usr/bin/{bunzip2,bzcat,bzip2}
	ln -sv bzip2 /bin/bunzip2
	ln -sv bzip2 /bin/bzcat

	doClose
}

install_pkgconfig()
{
	doOpen "pkg-config-"

	./configure --prefix=/usr              \
	            --with-internal-glib       \
	            --disable-host-tool        \
	            --docdir=/usr/share/doc/pkg-config-${version}

	doMake

	doClose
}

install_ncurses()
{
	doOpen "ncurses-"

	sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in

	./configure --prefix=/usr           \
	            --mandir=/usr/share/man \
	            --with-shared           \
	            --without-debug         \
	            --without-normal        \
	            --enable-pc-files       \
	            --enable-widec

	make
	make install

	mv -v /usr/lib/libncursesw.so.6* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so

	for lib in ncurses form panel menu ; do
	    rm -vf                    /usr/lib/lib${lib}.so
	    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
	    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
	done

	rm -vf                     /usr/lib/libcursesw.so
	echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
	ln -sfv libncurses.so      /usr/lib/libcurses.so

	mkdir -v       /usr/share/doc/ncurses-${version}
	cp -v -R doc/* /usr/share/doc/ncurses-${version}

	doClose
}

install_attr()
{
	name="attr-"
	version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.src\.tar.*/\1/g")
	echo "Install ${name}${version}..."
	tar -xf ${name}${version}.src.tar*
	cd ${name}${version}

	sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
	sed -i -e "/SUBDIRS/s|man[25]||g" man/Makefile
	sed -i 's:{(:\\{(:' test/run

	./configure --prefix=/usr \
	            --bindir=/bin \
	            --disable-static

	make
	make tests root-tests
	make install install-dev install-lib
	chmod -v 755 /usr/lib/libattr.so

	mv -v /usr/lib/libattr.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so

	cd ..
	rm -rf ${name}${version}
}

install_acl()
{
	name="acl-"
	version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.src\.tar.*/\1/g")
	echo "Install ${name}${version}..."
	tar -xf ${name}${version}.src.tar*
	cd ${name}${version}

	sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
	sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
	sed -i 's/{(/\\{(/' test/run
	sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" \
	    libacl/__acl_to_any_text.c

	./configure --prefix=/usr    \
	            --bindir=/bin    \
	            --disable-static \
	            --libexecdir=/usr/lib

	make
	make install install-dev install-lib
	chmod -v 755 /usr/lib/libacl.so

	mv -v /usr/lib/libacl.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so

	cd ..
	rm -rf ${name}${version}
}

install_libcap()
{
	doOpen "libcap-"

	sed -i '/install.*STALIBNAME/d' libcap/Makefile

	make
	make RAISE_SETFCAP=no lib=lib prefix=/usr install
	chmod -v 755 /usr/lib/libcap.so

	mv -v /usr/lib/libcap.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so

	doClose
}

install_sed()
{
	doOpen "sed-"

	sed -i 's/usr/tools/'                 build-aux/help2man
	sed -i 's/testsuite.panic-tests.sh//' Makefile.in

	./configure --prefix=/usr --bindir=/bin

	make
	make html
	make check

	make install
	install -d -m755           /usr/share/doc/sed-${version}
	install -m644 doc/sed.html /usr/share/doc/sed-${version}

	doClose
}

install_shadow()
{
	doOpen "shadow-"

	sed -i 's/groups$(EXEEXT) //' src/Makefile.in
	find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
	find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
	find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

	sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
	       -e 's@/var/spool/mail@/var/mail@' etc/login.defs

	sed -i 's/1000/999/' etc/useradd

	./configure --sysconfdir=/etc --with-group-name-max-length=32

	make
	make install
	mv -v /usr/bin/passwd /bin

	pwconv
	grpconv

	sed -i 's/yes/no/' /etc/default/useradd

	passwd root

	doClose
}

install_psmisc()
{
	doOpen "psmisc-"

	./configure --prefix=/usr
	make
	make install

	mv -v /usr/bin/fuser   /bin
	mv -v /usr/bin/killall /bin

	doClose
}

install_ianaetc()
{
	doOpen "iana-etc-"

	make
	make install

	doClose
}

install_bison()
{
	doOpen "bison-"

	./configure --prefix=/usr --docdir=/usr/share/doc/bison-${version}
	make
	make install

	doClose
}

install_flex()
{
	doOpen "flex-"

	sed -i "/math.h/a #include <malloc.h>" src/flexdef.h

	HELP2MAN=/tools/bin/true \
	./configure --prefix=/usr --docdir=/usr/share/doc/flex-${version}

	doMake
	ln -s flex /usr/bin/lex

	doClose
}

install_grep()
{
	doOpen "grep-"

	./configure --prefix=/usr --bindir=/bin
	doMake

	doClose
}

install_bash()
{
	doOpen "bash-"

	patch -Np1 -i ../bash-4.4-upstream_fixes-1.patch

	./configure --prefix=/usr                       \
	            --docdir=/usr/share/doc/bash-4.4 \
	            --without-bash-malloc               \
	            --with-installed-readline

	doMake
	chown -Rv nobody .

	su nobody -s /bin/bash -c "PATH=$PATH make tests"
	make install
	mv -vf /usr/bin/bash /bin

	exec /bin/bash --login +h

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

	su nobody -s /bin/bash \
	          -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"

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
	su nobody -s /bin/bash -c "PATH=$PATH make -k check"

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
	DIRLOG='LOG2/'

	echo "install zlib..." && install_zlib &> ${DIRLOG}zlib.log && read
	echo "install file..." && install_packet "file-" &> ${DIRLOG}file.log && read
	echo "install readline..." && install_readline &> ${DIRLOG}readline.log && read
	echo "install m4..." && install_packet "m4-" &> ${DIRLOG}m4.log && read
	echo "install bc..." && install_bc &> ${DIRLOG}bc.log && read
	echo "install binutils..." && install_binutils &> ${DIRLOG}binutils.log && read
	echo "install gmp..." && install_gmp &> ${DIRLOG}gmp.log && read
	echo "install mpfr..." && install_mpfr &> ${DIRLOG}mpfr.log && read
	echo "install mpc..." && install_mpc &> ${DIRLOG}mpc.log && read
	echo "install gcc..." && install_gcc &> ${DIRLOG}gcc.log && read
	echo "install bzip2..." && install_bzip2 &> ${DIRLOG}bzip2.log && read
	echo "install pkg-config..." && install_pkgconfig &> ${DIRLOG}pkgconfig.log && read
	echo "install ncurses..." && install_ncurses &> ${DIRLOG}ncurses.log && read
	echo "install attr..." && install_attr &> ${DIRLOG}attr.log && read
	echo "install acl..." && install_acl &> ${DIRLOG}acl.log && read
	echo "install libcap..." && install_libcap &> ${DIRLOG}libcap.log && read
	echo "install sed..." && install_sed &> ${DIRLOG}sed.log && read
	echo "install shadow..." && install_shadow &> ${DIRLOG}shadow.log && read
	echo "install psmisc..." && install_psmisc &> ${DIRLOG}psmisc.log && read
	echo "install iana-etc..." && install_ianaetc &> ${DIRLOG}iana-etc.log && read
	echo "install bison..." && install_bison &> ${DIRLOG}bison.log && read
	echo "install flex..." && install_flex &> ${DIRLOG}flex.log && read
	echo "install grep..." && install_grep &> ${DIRLOG}grep.log && read
	echo "install bash..." && install_bash &> ${DIRLOG}bash.log && read
	echo "install libtool..." && install_packet "libtool-" &> ${DIRLOG}libtool.log && read
	echo "install gdbm..." && install_gdbm &> ${DIRLOG}gdbm.log && read
	echo "install gperf..." && install_gperf &> ${DIRLOG}gperf.log && read
	echo "install expat..." && install_expat &> ${DIRLOG}expat.log && read
	echo "install inetutils..." && install_inetutils &> ${DIRLOG}inetutils.log && read
	echo "install perl..." && install_perl &> ${DIRLOG}perl.log && read
	echo "install XML-Parser..." && install_xmlparser &> ${DIRLOG}xmlparser.log && read
	echo "install intltool..." && install_intltool &> ${DIRLOG}intltool.log && read
	echo "install autoconf..." && install_packet "autoconf-" &> ${DIRLOG}autoconf.log && read
	echo "install automake..." && install_automake &> ${DIRLOG}automake.log && read
	echo "install xz..." && install_xz &> ${DIRLOG}xz.log && read
	echo "install kmod..." && install_kmod &> ${DIRLOG}kmod.log && read
	echo "install gettext..." && install_gettext &> ${DIRLOG}gettext.log && read
	echo "install procpsng..." && install_procpsng &> ${DIRLOG}procpsng.log && read
	echo "install e2fsprogs..." && install_e2fsprogs &> ${DIRLOG}e2fsprogs.log && read
	echo "install coreutils..." && install_coreutils &> ${DIRLOG}coreutils.log && read
	echo "install diffutils..." && install_packet "diffutils-" &> ${DIRLOG}diffutils.log && read
	echo "install gawk..." && install_packet "gawk-" &> ${DIRLOG}gawk.log && read
	echo "install findutils..." && install_findutils &> ${DIRLOG}findutils.log && read
	echo "install groff..." && install_groff &> ${DIRLOG}groff.log && read
	echo "install grub..." && install_grub &> ${DIRLOG}grub.log && read
	echo "install less..." && install_less &> ${DIRLOG}less.log && read
	echo "install gzip..." && install_gzip &> ${DIRLOG}gzip.log && read
	echo "install iproute2..." && install_iproute2 &> ${DIRLOG}iproute2.log && read
	echo "install kdb..." && install_kdb &> ${DIRLOG}kdb.log && read
	echo "install libpipeline..." && install_libpipeline &> ${DIRLOG}libpipeline.log && read
	echo "install make..." && install_make &> ${DIRLOG}make.log && read
	echo "install patch..." && install_packet "patch-" &> ${DIRLOG}patch.log && read
	echo "install sysklogd..." && install_sysklogd &> ${DIRLOG}sysklogd.log && read
	echo "install sysvinit..." && install_sysvinit &> ${DIRLOG}sysvinit.log && read
	echo "install eudev..." && install_eudev &> ${DIRLOG}eudev.log && read
	echo "install utillinux..." && install_utillinux &> ${DIRLOG}utillinux.log && read
	echo "install mandb..." && install_mandb &> ${DIRLOG}mandb.log && read
	echo "install tar..." && install_tar &> ${DIRLOG}tar.log && read
	echo "install vim..." && install_vim &> ${DIRLOG}vim.log && read
}

sysfile_setup()
{
	mkdir -pv $LFS/{dev,proc,sys,run}

	mknod -m 600 $LFS/dev/console c 5 1
	mknod -m 666 $LFS/dev/null c 1 3

	mount -v --bind /dev $LFS/dev

	mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
	mount -vt proc proc $LFS/proc
	mount -vt sysfs sysfs $LFS/sys
	mount -vt tmpfs tmpfs $LFS/run

	if [ -h $LFS/dev/shm ]; then
		mkdir -pv $LFS/$(readlink $LFS/dev/shm)
	fi


	su root
	chroot "$LFS" /tools/bin/env -i \
		HOME=/root                  \
		TERM="$TERM"                \
		PS1='(lfs chroot) \u:\w\$ ' \
		PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
		/tools/bin/bash --login +h


	mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
	mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
	install -dv -m 0750 /root
	install -dv -m 1777 /tmp /var/tmp
	mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
	mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
	mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
	mkdir -v  /usr/libexec
	mkdir -pv /usr/{,local/}share/man/man{1..8}

	case $(uname -m) in
		x86_64) mkdir -v /lib64 ;;
	esac

	mkdir -v /var/{log,mail,spool}
	ln -sv /run /var/run
	ln -sv /run/lock /var/lock
	mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}

	ln -sv /tools/bin/{bash,cat,dd,echo,ln,pwd,rm,stty} /bin
	ln -sv /tools/bin/{install,perl} /usr/bin
	ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
	ln -sv /tools/lib/libstdc++.{a,so{,.6}} /usr/lib
	ln -sv bash /bin/sh

	ln -sv /proc/self/mounts /etc/mtab

	cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

	cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
nogroup:x:99:
users:x:999:
EOF

	exec /tools/bin/bash --login +h

	touch /var/log/{btmp,lastlog,faillog,wtmp}
	chgrp -v utmp /var/log/lastlog
	chmod -v 664  /var/log/lastlog
	chmod -v 600  /var/log/btmp

	DIRLOG='LOG2/'
	mkdir ${DIRLOG}

	echo "install API header..." && install_apiheader &> ${DIRLOG}API_header.log && read
	echo "install man-pages..." && install_man_pages &> ${DIRLOG}man-pages.log && read
	echo "install glibc..." && install_glibc &> ${DIRLOG}glibc.log && read

	mv -v /tools/bin/{ld,ld-old}
	mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
	mv -v /tools/bin/{ld-new,ld}
	ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld

	gcc -dumpspecs | sed -e 's@/tools@@g'                   \
		-e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
		-e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
		`dirname $(gcc --print-libgcc-file-name)`/specs

	echo 'int main(){}' > dummy.c
	cc dummy.c -v -Wl,--verbose &> dummy.log
	readelf -l a.out | grep ': /lib'

	grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
	grep -B1 '^ /usr/include' dummy.log
	grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
	grep "/lib.*/libc.so.6 " dummy.log
	grep found dummy.log

	rm -v dummy.c a.out dummy.log

	sysfile_launch
}

sysfile_setup