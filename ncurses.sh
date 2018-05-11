install_ncurses()
{
    version_ncurses=6.0
    tar -xf ncurses-${version_ncurses}.tar.gz
    cd ncurses-${version_ncurses}

    sed -i s/mawk// configure

    ./configure --prefix=/tools \
                --with-shared   \
                --without-debug \
                --without-ada   \
                --enable-widec  \
                --enable-overwrite

    make
    make install

    cd ..
    rm -rf ncurses-${version_ncurses}
}
