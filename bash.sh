install_bash()
{
    name="bash-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

    ./configure --prefix=/tools --without-bash-malloc

    make
    make install

    ln -sv bash /tools/bin/sh

    cd ..
    rm -rf ${name}${version}
}
