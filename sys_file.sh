install_apiheader()
{
    name="linux-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

	make mrproper

	make INSTALL_HDR_PATH=dest headers_install
	find dest/include \( -name .install -o -name ..install.cmd \) -delete
	cp -rv dest/include/* /usr/include

    cd ..
    rm -rf ${name}${version}
}

install_man_pages()
{
    name="man-pages-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

	make install

    cd ..
    rm -rf ${name}${version}
}

install_gcc()
{
    name="gcc-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

	patch -Np1 -i ../glibc-2.27-fhs-1.patch

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

    cd ..
    cd ..
    rm -rf ${name}${version}
}

install_zlib()
{
    name="zlib-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

	./configure --prefix=/usr
	make
	make check
	make install

	mv -v /usr/lib/libz.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so

    cd ..
    rm -rf ${name}${version}
}

install_packet()
{
    name=$1
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

	./configure --prefix=/usr
	make
	make check
	make install

    cd ..
    rm -rf ${name}${version}
}

install_readline()
{
    name="readline-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

	sed -i '/MV.*old/d' Makefile.in
	sed -i '/{OLDSUFF}/c:' support/shlib-install

	./configure --prefix=/usr    \
	            --disable-static \
	            --docdir=/usr/share/doc/readline-7.0

	make SHLIB_LIBS="-L/tools/lib -lncursesw"
	make SHLIB_LIBS="-L/tools/lib -lncurses" install

	mv -v /usr/lib/lib{readline,history}.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
	ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so

	install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-7.0

    cd ..
    rm -rf ${name}${version}
}

install_bc()
{
    name="bc-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

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
	
    cd ..
    rm -rf ${name}${version}
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

	echo "install API header..." && install_apiheader &> ${DIRLOG}API_header.log
	echo "install man-pages..." && install_man_pages &> ${DIRLOG}man-pages.log
	echo "install gcc..." && install_gcc &> ${DIRLOG}gcc.log

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

	echo "install zlib..." && install_zlib &> ${DIRLOG}zlib.log
	echo "install file..." && install_packet "file-" &> ${DIRLOG}file.log
	echo "install readline..." && install_readline &> ${DIRLOG}readline.log
	echo "install m4..." && install_packet "m4-" &> ${DIRLOG}m4.log

}
