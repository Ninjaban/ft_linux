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

	make install
	mv -vf /usr/bin/bash /bin

	exec /bin/bash --login +h

	doClose
}

sysfile_launch()
{
	echo "install zlib..." && install_zlib && read
	echo "install file..." && install_packet "file-" && read
	echo "install readline..." && install_readline && read
	echo "install m4..." && install_packet "m4-" && read
	echo "install bc..." && install_bc && read
	echo "install binutils..." && install_binutils && read
	echo "install gmp..." && install_gmp  && read
	echo "install mpfr..." && install_mpfr && read
	echo "install mpc..." && install_mpc && read
	echo "install gcc..." && install_gcc && read
	echo "install bzip2..." && install_bzip2 && read
	echo "install pkg-config..." && install_pkgconfig && read
	echo "install ncurses..." && install_ncurses && read
	echo "install attr..." && install_attr && read
	echo "install acl..." && install_acl && read
	echo "install libcap..." && install_libcap && read
	echo "install sed..." && install_sed && read
	echo "install shadow..." && install_shadow && read
	echo "install psmisc..." && install_psmisc && read
	echo "install iana-etc..." && install_ianaetc && read
	echo "install bison..." && install_bison && read
	echo "install flex..." && install_flex && read
	echo "install grep..." && install_grep && read
	echo "install bash..." && install_bash && read
}

sysfile_setup()
{
	touch /var/log/{btmp,lastlog,faillog,wtmp}
	chgrp -v utmp /var/log/lastlog
	chmod -v 664  /var/log/lastlog
	chmod -v 600  /var/log/btmp

	echo "install API header..." && install_apiheader && read
	echo "install man-pages..." && install_man_pages && read
	echo "install glibc..." && install_glibc && read

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
