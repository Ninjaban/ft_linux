install_apiheader()
{
    version_apiheader=4.12.7
    tar -xf linux-${version_apiheader}.tar.xz
    cd linux-${version_apiheader}
    
    make mrproper

    make INSTALL_HDR_PATH=dest headers_install
    cp -rv dest/include/* /tools/include

    cd ..
    rm -rf linux-${version_apiheader}
}
