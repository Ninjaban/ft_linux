install_make()
{
    version_make=4.2.1
    tar -xf make-${version_make}.tar.bz2
    cd make-${version_make}

    ./configure --prefix=/tools --without-guile

    make
    make install

    cd ..
    rm -rf make-${version_make}
}
