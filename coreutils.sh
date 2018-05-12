install_coreutils()
{
    name="coreutils-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

    ./configure --prefix=/tools --enable-install-program=hostname

    make
    make install

    cd ..
    rm -rf ${name}${version}
}
