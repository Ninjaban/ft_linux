install_tcl-core()
{
    name="tcl-core-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}
    
    cd unix
    ./configure --prefix=/tools

    make
    make install

    chmod -v u+w /tools/lib/libtcl8.6.so
    make install-private-headers
    ln -sv tclsh8.6 /tools/bin/tclsh

    cd ..
    rm -rf ${name}${version}
}
