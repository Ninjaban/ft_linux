install_bash()
{
    version_bash=4.4
    tar -xf bash-${version_bash}.tar.gz
    cd bash-${version_bash}

    ./configure --prefix=/tools --without-bash-malloc

    make
    make install

    ln -sv bash /tools/bin/sh

    cd ..
    rm -rf bash-${version_bash}
}
