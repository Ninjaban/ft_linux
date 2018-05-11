install_coreutils()
{
    version_coreutils=8.27
    tar -xf coreutils-${version_coreutils}.tar.xz
    cd coreutils-${version_coreutils}

    ./configure --prefix=/tools --enable-install-program=hostname

    make
    make install

    cd ..
    rm -rf coreutils-${version_coreutils}
}
