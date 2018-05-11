install_check()
{
    version_check=0.11.0
    tar -xf check-${version_check}.tar.gz
    cd check-${version_check}
    
    PKG_CONFIG= ./configure --prefix=/tools

    make
    make install

    cd ..
    rm -rf check-${version_check}
}
