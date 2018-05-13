install_bzip2()
{
    name="bzip2-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    echo "Install ${name}${version}..."
    tar -xf ${name}${version}.tar*
    cd ${name}${version}
    
    make
    make PREFIX=/tools install

    cd ..
    rm -rf ${name}${version}
}
