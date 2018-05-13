install_bison()
{
    name="bison-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}
    
    ./configure --prefix=/tools

    make
    make install

    cd ..
    rm -rf ${name}${version}
}
