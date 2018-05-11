install_gettext()
{
    version_gettext=0.19.8.1
    tar -xf gettext-${version_gettext}.tar.xz
    cd gettext-${version_gettext}

    cd gettext-tools
    EMACS="no" ./configure --prefix=/tools --disable-shared

    make -C gnulib-lib
    make -C intl pluralx.c
    make -C src msgfmt
    make -C src msgmerge
    make -C src xgettext

    cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin

    cd ..
    rm -rf gettext-${version_gettext}
}
