install_expect()
{
    name="expect"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}

    cp -v configure{,.orig}
    sed 's:/usr/local/bin:/bin:' configure.orig > configure

    ./configure --prefix=/tools       \
                --with-tcl=/tools/lib \
                --with-tclinclude=/tools/include

    make
    make SCRIPTS="" install

    cd ..
    rm -rf ${name}${version}
}
