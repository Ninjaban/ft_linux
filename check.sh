install_check()
{
    name="check-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    tar -xf ${name}${version}.tar*
    cd ${name}${version}
    
    PKG_CONFIG= ./configure --prefix=/tools

    make
    make install

    cd ..
    rm -rf ${name}${version}
}
