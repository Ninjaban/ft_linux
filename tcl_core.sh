install_tcl-core()
{
    name="tcl-core"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)-src\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}-src.tar*
    cd ${name}${version}-src
    
    cd unix
    ./configure --prefix=/tools

    make
    make install

    chmod -v u+w /tools/lib/libtcl8.6.so
    make install-private-headers
    ln -sv tclsh8.6 /tools/bin/tclsh

    cd ..
    rm -rf ${name}${version}-src
}
