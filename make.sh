install_make()
{
    name="make-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

    ./configure --prefix=/tools --without-guile

    make
    make install

    cd ..
    rm -rf ${name}${version}
}
