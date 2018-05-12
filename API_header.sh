install_apiheader()
{
    name="linux-"
    version=$(find . -name "${name}*" -print0 | sed -r "s/.*${name}(.*)\.tar.*/\1/g")
    tar -xf ${name}${version}.tar*
    cd ${name}${version}
    
    make mrproper

    make INSTALL_HDR_PATH=dest headers_install
    cp -rv dest/include/* /tools/include

    cd ..
    rm -rf ${name}${version}
}
